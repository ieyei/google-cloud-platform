

## Adding custom taints to a node

```
$ kubectl get nodes
NAME                                        STATUS   ROLES    AGE     VERSION
gke-my-cluster-default-pool-e4bfcffd-d1p1   Ready    <none>   2m42s   v1.15.9-gke.8
gke-my-cluster-default-pool-e4bfcffd-dmc2   Ready    <none>   2m43s   v1.15.9-gke.8
gke-my-cluster-default-pool-e4bfcffd-pjt2   Ready    <none>   2m41s   v1.15.9-gke.8
```



`gke-my-cluster-default-pool-e4bfcffd-pjt2`  노드에 pod가 배포되지 않도록 설정

```
$ kubectl taint node gke-my-cluster-default-pool-e4bfcffd-pjt2 node-type=stage:NoSchedule
```



새로운 pod가 배포될 때 `gke-my-cluster-default-pool-e4bfcffd-pjt2` 노드에는 배포되지 않음

```
$ kubectl run test --image busybox --replicas 5 -- sleep 99999

$ kubectl get po -o wide
```



## Using labels and selectors to constrain pod scheduling

pod가 배포될 node에 label 설정  `node-type=production`

```
kubectl label node gke-my-cluster-default-pool-e4bfcffd-d1p1 node-type=production
kubectl label node gke-my-cluster-default-pool-e4bfcffd-dmc2 node-type=production
```



node label 확인

```
$ kubectl get nodes -l node-type=production
NAME                                        STATUS   ROLES    AGE   VERSION
gke-my-cluster-default-pool-e4bfcffd-d1p1   Ready    <none>   15m   v1.15.9-gke.8
gke-my-cluster-default-pool-e4bfcffd-dmc2   Ready    <none>   15m   v1.15.9-gke.8
```



### Scheduling pods to specific nodes

deployment yaml 수정

(nodeSelector 부분 추가)

```
...
    spec:
      containers:
      - args:
        - sleep
        - "99999"
        image: busybox
        imagePullPolicy: Always
        name: test
      nodeSelector:
        node-type: production
...        
```



`gke-my-cluster-default-pool-e4bfcffd-pjt2` 노드에는 배포되지 않음을 확인

```
$ k get po -o wide 
NAME                         READY   STATUS     RESTARTS   AGE     IP           NODE                                     
mongo-mongodb-arbiter-0      1/1     Running    5          102m    10.36.3.9    gke-my-cluster-default-pool-e4bfcffd-dmc2
mongo-mongodb-primary-0      2/2     Running    0          161m    10.36.3.14   gke-my-cluster-default-pool-e4bfcffd-dmc2
mongo-mongodb-secondary-0    2/2     Running    0          101m    10.36.3.13   gke-my-cluster-default-pool-e4bfcffd-dmc2
php-apache-5986bb6b9-vct8z   1/1     Running    0          162m    10.36.3.10   gke-my-cluster-default-pool-e4bfcffd-dmc2
test-5b98dc6c-8dxlh          1/1     Running    0          3m45s   10.36.4.6    gke-my-cluster-default-pool-e4bfcffd-d1p1
test-5b98dc6c-bljjl          1/1     Running    0          3m42s   10.36.4.9    gke-my-cluster-default-pool-e4bfcffd-d1p1
test-5b98dc6c-d2wq6          1/1     Running    0          3m45s   10.36.4.8    gke-my-cluster-default-pool-e4bfcffd-d1p1
test-5b98dc6c-hq7zz          1/1     Running    0          3m42s   10.36.4.10   gke-my-cluster-default-pool-e4bfcffd-d1p1
test-5b98dc6c-pxm6b          1/1     Running    0          3m45s   10.36.4.7    gke-my-cluster-default-pool-e4bfcffd-d1p1
```



