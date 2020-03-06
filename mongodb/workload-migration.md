# Workload Migration

작업 순서

* 기존 노드풀 예약 불가능으로 표시 ( cordon )
* 기존 노드풀에서 실행되는 작업 부하 배출 ( drain )
* 기존 노드풀 삭제



## 정보확인

cluster name, zone 기본 설정

```
gcloud config set compute/zone us-central1-a

gcloud config set container/cluster my-cluster
```



노드풀 정보 확인

```
$ gcloud container node-pools list
NAME          MACHINE_TYPE   DISK_SIZE_GB  NODE_VERSION
default-pool  n1-standard-2  10            1.15.9-gke.8
pool-1        n1-standard-1  100           1.15.9-gke.8
```



노드 정보 확인

```
$ kubectl get nodes
NAME                                        STATUS   ROLES    AGE   VERSION
gke-my-cluster-default-pool-e4bfcffd-7x42   Ready    <none>   29m   v1.15.9-gke.8
gke-my-cluster-pool-1-9a5d9aed-w2r5         Ready    <none>   16m   v1.15.9-gke.8
```



## 워크로드 마이그레이션

실행 중인 pod 정보 확인

```
kubectl get pods -o=wide
```



### 1.노드풀 차단(cordon)

기존 노드풀의 노드들을 예약 불가능으로 표시.



`pool-1`의 노드 차단

```
kubectl get nodes -l cloud.google.com/gke-nodepool=pool-1 
```



```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=pool-1 -o=name); do
  kubectl cordon "$node";
done
```

결과확인

```
$ kubectl get nodes
NAME                                        STATUS                     ROLES    AGE   VERSION
gke-my-cluster-default-pool-e4bfcffd-7x42   Ready                      <none>   43m   v1.15.9-gke.8
gke-my-cluster-pool-1-9a5d9aed-w2r5         Ready,SchedulingDisabled   <none>   30m   v1.15.9-gke.8

```





### 2.노드풀 배출(drain)

기존 노드풀의 노드에서 실행 중인 워크로드 정상적으로 제거.

```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=pool-1 -o=name); do
  kubectl drain --force --ignore-daemonsets --delete-local-data --grace-period=10 "$node";
done

```



결과확인: 모든 pod가 default-pool에서 실행하는 것 확인

```
kubectl get pods -o=wide
```



### 3.이전 노드 풀 삭제

노드 풀 삭제

```
gcloud container node-pools delete pool-1
```



결과확인

```
gcloud container node-pools list
```



### Ref

[여러 머신 유형에 워크로드 마이그레이션](https://cloud.google.com/kubernetes-engine/docs/tutorials/migrating-node-pool#step_4_migrate_the_workloads)

[cordon and drain script](https://gist.github.com/drubin/c3e2131ada657b6bcb4f1ac64d789c87)



---



## 드레이닝으로 클러스터 크기 줄이기

작업 순서

**1.노드 풀의 Autoscaling 기능 끄기 !!!!** 

2.클러스터 resize

- pod 드레이닝
- 인스턴스 삭제 (무작위)

3.노드 풀 Autoscaling 기능 on



노드정보 확인

```
$ kubectl get nodes
NAME                                        STATUS   ROLES    AGE     VERSION
gke-my-cluster-default-pool-e4bfcffd-7948   Ready    <none>   7m17s   v1.15.9-gke.8
gke-my-cluster-default-pool-e4bfcffd-7x42   Ready    <none>   71m     v1.15.9-gke.8

```



클러스터 resize

```
gcloud beta container clusters resize [CLUSTER_NAME] --node-pool [NODE_POOL] \
--num-nodes [NUM_NODES]

gcloud beta container clusters resize my-cluster --node-pool default-pool \
--num-nodes 1
```





### Ref

[클러스터 크기 조절](https://cloud.google.com/kubernetes-engine/docs/how-to/resizing-a-cluster)





