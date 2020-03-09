#!/bin/bash
echo `date`
WORK_ROOT=$(cd "$(dirname "$0")" && pwd)
cd $WORK_ROOT
CPOD=$(kubectl get pod -l app=mongo-backup -o jsonpath="{.items[0].metadata.name}")
kubectl cp backup.sh $CPOD:/root/backup.sh
kubectl exec $CPOD -- sh /root/backup.sh
