

# Mongodb chart upgrade

## mongodb 상태

**terminal #1**

```
$ k get po -w
NAME                         READY   STATUS    RESTARTS   AGE
mongo-mongodb-arbiter-0      1/1     Running   0          8m9s
mongo-mongodb-primary-0      2/2     Running   0          8m9s
mongo-mongodb-secondary-0    2/2     Running   0          8m9s
mongo-mongodb-secondary-1    2/2     Running   1          3m54s
mongo-mongodb-secondary-2    2/2     Running   1          3m54s
```



**terminal #2**

chart 변경

vi ./mongodb/values-production.yaml

```
...
  replicas:
    secondary: 1   # 3 -> 1로 변경
    arbiter: 1
...    
```



**statefulset은 끝자리 숫자가 큰 pod부터 삭제됨**

chart upgrade

```
$ helm upgrade mongo ./mongodb -f ./mongodb/values-production.yaml
```



**terminal #1**

```
$ k get po -w
NAME                         READY   STATUS    RESTARTS   AGE
mongo-mongodb-arbiter-0      1/1     Running   0          8m9s
mongo-mongodb-primary-0      2/2     Running   0          8m9s
mongo-mongodb-secondary-0    2/2     Running   0          8m9s
mongo-mongodb-secondary-1    2/2     Running   1          3m54s
mongo-mongodb-secondary-2    2/2     Running   1          3m54s
php-apache-5986bb6b9-8shjc   1/1     Running   0          19h

mongo-mongodb-secondary-2    2/2     Terminating   1          7m43s
mongo-mongodb-secondary-1    2/2     Terminating   1          7m43s
mongo-mongodb-secondary-2    1/2     Terminating   1          7m56s
mongo-mongodb-secondary-1    1/2     Terminating   1          8m2s
mongo-mongodb-secondary-1    0/2     Terminating   1          8m13s
mongo-mongodb-secondary-1    0/2     Terminating   1          8m13s
mongo-mongodb-secondary-2    0/2     Terminating   1          8m14s
mongo-mongodb-secondary-2    0/2     Terminating   1          8m14s
mongo-mongodb-secondary-1    0/2     Terminating   1          8m14s
mongo-mongodb-secondary-1    0/2     Terminating   1          8m14s
mongo-mongodb-secondary-2    0/2     Terminating   1          8m22s
mongo-mongodb-secondary-2    0/2     Terminating   1          8m23s



$ k get po
NAME                         READY   STATUS    RESTARTS   AGE
mongo-mongodb-arbiter-0      1/1     Running   0          13m
mongo-mongodb-primary-0      2/2     Running   0          13m
mongo-mongodb-secondary-0    2/2     Running   0          13m
```

