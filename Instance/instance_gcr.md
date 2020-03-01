



## gcloud 설치

gcloud 설치 확인

```
$ gcloud version
Google Cloud SDK 279.0.0
alpha 2020.01.31
beta 2020.01.31
bq 2.0.53
core 2020.01.31
gsutil 4.47
kubectl 2020.01.31
```



설치가 안되었을 경우 설치방법

[Installing from versioned archives](https://cloud.google.com/sdk/docs/downloads-versioned-archives?hl=ko)

* 환경변수 설정

  ```
  export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
  ```

* Cloud SDK 배포 URI를 패키지 소스에 추가

  ```
  echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  ```

* Google cloud 공개키 

  ```
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  ```

* 설치

  ```
  sudo apt-get update && sudo apt-get install google-cloud-sdk
  ```



## Instance 사용 설정

[VM 액세스 범위 변경](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#changeserviceaccountandscopes)

Instance에서 gcr 기능을 이용하기 위해서는 Instance scope에 storage-rw를 추가해야 함.

(Instance 생성 시 설정 or 기 생성 시 stop 후 설정 적용 가능)



vm stop 후 cloudshell에서 실행 

```
# Instance name : instance-5 )
gcloud compute instances set-service-account instance-5 --scopes=storage-rw --zone=us-central1-a
```



## Docker 인증

1.Docker 인증

[독립형 Docker 사용자 인증 정보 도우미](https://cloud.google.com/container-registry/docs/advanced-authentication#gcloud_as_a_docker_credential_helper)

* docker-credential-gcr 다운로드

```
VERSION=2.0.0
OS=linux  
ARCH=amd64  

curl -fsSL "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${VERSION}/docker-credential-gcr_${OS}_${ARCH}-${VERSION}.tar.gz" \
    | tar xz --to-stdout ./docker-credential-gcr \
    | sudo tee /usr/bin/docker-credential-gcr > /dev/null && sudo chmod +x /usr/bin/docker-credential-gcr
```

* docker 구성

```
docker-credential-gcr configure-docker
```



## Image push

* image push

```
sudo docker pull busybox
sudo docker tag busybox gcr.io/prime-elf-161722/busybox:v1

sudo docker push gcr.io/prime-elf-161722/busybox:v1
```



* image 확인

```
gcloud container images list
```



* image 삭제

```
# 다이제스트로 식별하는 이미지
gcloud container images delete [HOSTNAME]/[PROJECT-ID]/[IMAGE]@[IMAGE_DIGEST]

# 태그로 식별하고 여러 태그가 있는 이미지:
gcloud container images delete [HOSTNAME]/[PROJECT-ID]/[IMAGE]:[TAG] --force-delete-tags
```



---

아래는 참조용.





## Service account

[서비스 계정 생성 및 관리](https://cloud.google.com/iam/docs/creating-managing-service-accounts?hl=ko#iam-service-accounts-create-gcloud)

### Service account 생성 및 설정(화면)

IAM & Admin > Service Accounts > create service account

name: sa-here

editor 역할로 추가

key json 파일 생성 및 다운로드



### Service account 생성 및 설정(gcloud)

**cloudshell에서 실행**

1.서비스 계정 만들기

```
gcloud iam service-accounts create sa-here \
    --description "SA for here" \
    --display-name "sa-here"
```

2.서비스 계정 키 만들기

```
# gcloud iam service-accounts keys create ~/key.json \
#  --iam-account [SA-NAME]@[PROJECT-ID].iam.gserviceaccount.com
  
gcloud iam service-accounts keys create ~/key.json \
  --iam-account sa-here@prime-elf-161722.iam.gserviceaccount.com
  
```



### Service account에 역할 부여

**cloudshell에서 실행**

서비스 계정에 역할 추가

```
# gcloud projects add-iam-policy-binding [PROJECT-ID] \
#   --member serviceAccount:[SA-NAME]@[PROJECT-ID].iam.gserviceaccount.com \
#   --role roles/editor


gcloud projects add-iam-policy-binding prime-elf-161722 \
  --member serviceAccount:sa-here@prime-elf-161722.iam.gserviceaccount.com \
  --role roles/editor
```



## Cloud SDK 설정(gcloud)

**cloudshell에서 실행**

1.서비스 계정 키를 VM에 복사 ( cloudshell -> VM )

```
# local의 key.json 파일을 instance-2서버의 홈디렉토리에 복사

gcloud compute scp keyfile.json instance-4:~/ --zone=us-central1-a
```



**VM에서 실행**

2.gcloud 설정

```
gcloud auth activate-service-account --key-file=keyfile.json
```



