



# Deploy a MongoDB database

```
# helm v3
$ helm install mongodb stable/mongodb --set mongodbRootPassword=password

NAME: mongodb
LAST DEPLOYED: Sun Feb 23 18:08:04 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

MongoDB can be accessed via port 27017 on the following DNS name from within your cluster:

    mongodb.default.svc.cluster.local

To get the root password run:

    export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace default mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 --decode)

To connect to your database run the following command:

    kubectl run --namespace default mongodb-client --rm --tty -i --restart='Never' --image bitnami/mongodb --command -- mongo admin --host mongodb --authenticationDatabase admin -u root -p $MONGODB_ROOT_PASSWORD

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/mongodb 27017:27017 &
    mongo --host 127.0.0.1 --authenticationDatabase admin -p $MONGODB_ROOT_PASSWORD
```





# Load some data in MongoDB

connect to the database

```
export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace default mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 --decode)


kubectl run --namespace default mongodb-client --rm --tty -i --restart='Never' --image bitnami/mongodb --command -- mongo admin --host mongodb --authenticationDatabase admin -u root -p $MONGODB_ROOT_PASSWORD
```



Load the data

```
db.myCollection.insertOne ( { key1: "value1" });
db.myCollection.insertOne ( { key2: "value2" });
```



retrieve the values

```
> db.myCollection.find()
{ "_id" : ObjectId("5e52433109152515b8102b00"), "key1" : "value1" }
{ "_id" : ObjectId("5e52433309152515b8102b01"), "key2" : "value2" }
```



# Back up MongoDB

```
apiVersion: batch/v1
kind: Job
metadata:
  name: mongodump
  #namespace: kube-system
spec:
  template:
    spec:
      containers:
      - name: mongodump
        image: bitnami/mongodb
        command: 
          - bash
          - -c
          - |
            mongodump --host mongodb -u root -p password -d admin -c myCollection --out /dump --verbose
        volumeMounts:
        - mountPath: "/dump"
          name: mongodump
      volumes:
      - name: mongodump
        emptyDir: {}
      restartPolicy: OnFailure
  backoffLimit: 4
```



# Simulate data loss in MongoDB

```
db.myCollection.deleteOne ({ key1: "value1" });
```



```
> db.myCollection.find()
{ "_id" : ObjectId("5e52433309152515b8102b01"), "key2" : "value2" }
```



# Restore the MongoDB database



```
mongorestore --host mongodb -u root -p password -d admin -c myCollection /dump --verbose
```

