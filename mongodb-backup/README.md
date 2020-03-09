# GCS에 Kubernetes Mongodb Backup



## GCS에 Bucket 생성

bucket name은 unique 해야 함.

```
$ gsutil mb -l asia gs://mongodb-backup123
```

bucket list 확인

```
$ gsutil ls
gs://mongodb-backup123/
```





## Service Account 생성

[서비스 계정 생성 및 관리](https://cloud.google.com/iam/docs/creating-managing-service-accounts?hl=ko#iam-service-accounts-create-gcloud)



### Service account 생성 및 설정(gcloud)

**cloudshell에서 실행**

1.서비스 계정 만들기

```
gcloud iam service-accounts create gcs-sa \
    --description "SA for gcs" \
    --display-name "gcs-sa"
```

2.서비스 계정 키 만들기

```
# gcloud iam service-accounts keys create ~/key.json \
#  --iam-account [SA-NAME]@[PROJECT-ID].iam.gserviceaccount.com
  
gcloud iam service-accounts keys create key.json \
  --iam-account gcs-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com
  
```

### 

### Service account에 역할 부여

**cloudshell에서 실행**

서비스 계정에 역할 추가(Storage Object Creator, Storage Object Viewer)

[gcp role](https://cloud.google.com/iam/docs/understanding-roles?hl=ko#storage-roles)

```
# gcloud projects add-iam-policy-binding [PROJECT-ID] \
#   --member serviceAccount:[SA-NAME]@[PROJECT-ID].iam.gserviceaccount.com \
#   --role roles/editor


gcloud projects add-iam-policy-binding prime-elf-161722 \
  --member serviceAccount:gcs-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --role roles/storage.objectCreator

gcloud projects add-iam-policy-binding prime-elf-161722 \
  --member serviceAccount:gcs-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --role roles/storage.objectViewer
```



### Secret 생성

```
$ kubectl create secret generic gcs-key --from-file=key.json
```



## Mongo backup pod

### Backup Pod 생성



* MONGO_URI : mongodb://[user]:[user password]@[mongodb svc]:27017/admin
* BUCKET_NAME : 위에서 생성한 gcs bucket name

[mongobackup.yaml](mongobackup.yaml)

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: mongo-backup
  name: mongo-backup
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo-backup
  strategy: {}
  template:
    metadata:
      labels:
        app: mongo-backup
    spec:
      containers:
      - image: ubuntu
        name: ubuntu
        command: ["/bin/sh"]
        args:
          - -c
          - |
            # google sdk install
            apt-get update && apt-get install -y curl python
            curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-280.0.0-linux-x86_64.tar.gz -o g-sdk.tar.gz
            tar xf g-sdk.tar.gz  -C /root
            #export PATH=$PATH:/root/google-cloud-sdk/bin
            echo "export PATH=$PATH:/root/google-cloud-sdk/bin" >> /root/.bashrc
            #cp -r /root/google-cloud-sdk/bin/* /usr/local/bin
            
            # mongodb client install
            apt-get install -y libcurl4 openssl
            cd /root
            curl -OL https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-4.2.3.tgz
            tar -zxf mongodb-linux-*-4.2.3.tgz && mv mongodb-linux-*-4.2.3 mongodb
            echo "export PATH=$PATH:/root/mongodb/bin" >> /root/.bashrc
            #cp -r /root/mongodb/bin/* /usr/local/bin
            mkdir /root/dump
            echo "====== install finished"
            tail -f /dev/null
        resources: {}
        volumeMounts:
        - name: google-cloud-key
          mountPath: /var/secrets/google
        env:
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: /var/secrets/google/key.json
        - name:  MONGO_URI
          value: "mongodb://root:password@mongodb:27017/admin"
        - name:  BUCKET_NAME
          value: mongodb-backup123
        resources: {}
      volumes:
      - name: google-cloud-key
        secret:
          secretName: gcs-key

```

```
kubectl apply -f mongobackup.yaml
```



### Pod 안에서 실행될 backup script

backup 설정 : mongodump --uri $MONGO_URI -c myCollection -o $BACKUP_PATH --quiet

copy to gcs : gsutil cp $BACKUP_PATH$BACKUP_FILENAME gs://$BUCKET_NAME/$BACKUP_FILENAME 2>&1



[backup.sh](backup.sh)

```

# Utility functions
get_log_date () {
    date +[%Y-%m-%d\ %H:%M:%S]
}
get_file_date () {
    date +%Y%m%d%H%M%S
}

# Validate needed ENV vars
if [ -z "$MONGO_URI" ]; then
    echo "$(get_log_date) MONGO_URI is unset or set to the empty string"
    exit 1
fi
if [ -z "$BUCKET_NAME" ]; then
    echo "$(get_log_date) BUCKET_NAME is unset or set to the empty string"
    exit 1
fi

# Path in which to create the backup (will get cleaned later)
BACKUP_PATH="/root/dump/"

# START
export PATH=$PATH:/root/google-cloud-sdk/bin:/root/mongodb/bin
echo "$(get_log_date) Mongo backup started"

# Activate google cloud service account
echo "$(get_log_date) Activating service account"
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS

# Backup filename
BACKUP_FILENAME="$(get_file_date).tar.gz"

# Create the backup
echo "$(get_log_date) [Step 1/3] Running mongodump from $MONGO_URI to $BACKUP_PATH"
mongodump --uri $MONGO_URI -c myCollection -o $BACKUP_PATH --quiet

# Compress
echo "$(get_log_date) [Step 2/3] Creating tar file"
tar -czf $BACKUP_PATH$BACKUP_FILENAME $BACKUP_PATH*

# Copy to Google Cloud Storage
echo "$(get_log_date) [Step 3/3] Uploading archive to Google Cloud Storage"
echo "Copying $BACKUP_PATH$BACKUP_FILENAME to gs://$BUCKET_NAME/$BACKUP_FILENAME"
gsutil cp $BACKUP_PATH$BACKUP_FILENAME gs://$BUCKET_NAME/$BACKUP_FILENAME 2>&1

# Clean
#echo "Removing backup data"
#rm -rf $BACKUP_PATH*

# FINISH
echo "$(get_log_date) Copying finished"
```



### Backup 실행

mongobackup.sh

```
#!/bin/bash
echo `date`
WORK_ROOT=$(cd "$(dirname "$0")" && pwd)
cd $WORK_ROOT
CPOD=$(kubectl get pod -l app=mongo-backup -o jsonpath="{.items[0].metadata.name}")
kubectl cp backup.sh $CPOD:/root/backup.sh
kubectl exec $CPOD -- sh /root/backup.sh
```



```
$ ./mongobackup.sh
Mon Mar 9 16:00:38 +09 2020
[2020-03-09 07:00:44] Mongo backup started
[2020-03-09 07:00:44] Activating service account
Activated service account credentials for: [gcs-sa@prime-elf-161722.iam.gserviceaccount.com]
[2020-03-09 07:00:45] [Step 1/3] Running mongodump from mongodb://root:password@mongodb:27017/admin to /root/dump/
[2020-03-09 07:00:45] [Step 2/3] Creating tar file
tar: Removing leading `/' from member names
[2020-03-09 07:00:45] [Step 3/3] Uploading archive to Google Cloud Storage
Copying /root/dump/20200309070045.tar.gz to gs://mongodb-backup123/20200309070045.tar.gz
Copying file:///root/dump/20200309070045.tar.gz [Content-Type=application/x-tar]...
/ [1 files][  365.0 B/  365.0 B]
Operation completed over 1 objects/365.0 B.
[2020-03-09 07:00:47] Copying finished
```



gcs 확인

```
$ gsutil ls gs://mongodb-backup123/
gs://mongodb-backup123/20200309070045.tar.gz
```

