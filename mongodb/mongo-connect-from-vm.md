# VM에서 K8s안의 Mongodb 접속

## Mongodb 설정

values.yaml 수정

```
...
service:
  annotations: {}
  type: NodePort   # 외부접속 허용을 위해 NodePort로 변경
  port: 27017
  nodePort: 30123	# worker node에서 서비스가 사용하는 port
...  
```



적용

```
helm upgrade mongodb ./mongodb
```





서비스 확인

- mongodb 서비스 포트 27017이 30123으로 매핑되어 있음.

```
$ kubectl get svc
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
kubernetes         ClusterIP   10.39.240.1     <none>        443/TCP           15d
mongodb            NodePort    10.39.252.131   <none>        27017:30123/TCP   43m
mongodb-headless   ClusterIP   None            <none>        27017/TCP         43m
```



worker nodes IP 확인

(Internal IP: 10.128.15.238, 10.128.15.239)

```
$ kubectl get nodes -o wide
NAME                                        STATUS   ROLES    AGE   VERSION         INTERNAL-IP     EXTERNAL-IP      OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-my-cluster-default-pool-e4bfcffd-8mzl   Ready    <none>   61m   v1.15.9-gke.8   10.128.15.238   104.197.64.112   Container-Optimized OS from Google   4.19.76+         docker://19.3.1
gke-my-cluster-default-pool-e4bfcffd-wz3j   Ready    <none>   61m   v1.15.9-gke.8   10.128.15.239   34.66.46.7       Container-Optimized OS from Google   4.19.76+         docker://19.3.1
```



## VM에서 mongodb 접속

VM IP : 10.128.15.213

### mongo client docker 실행

```
docker run --name mongodb-client -it -d bitnami/mongodb
docker exec -it mongodb-client bash
```



### mongodb 접속

host : 10.128.15.238 (kubernetes worker node ip)

port : 30123 (node port)

```
I have no name!@5ea63b42aac1:/$ mongo admin --host 10.128.15.238 --port 30123 --authenticationDatabase admin -u root -p password 
MongoDB shell version v4.0.14
connecting to: mongodb://10.128.15.238:30123/admin?authSource=admin&gssapiServiceName=mongodb
...

rs0:PRIMARY> show dbs
admin   0.000GB
config  0.000GB
local   0.000GB
rs0:PRIMARY> 

```



