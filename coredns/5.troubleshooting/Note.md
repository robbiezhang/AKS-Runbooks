## Check if the DNS pod is running
Use the kubectl get pods command to verify that the DNS pod is running.

Command:
```
kubectl get pods --namespace=kube-system -l k8s-app=kube-dns
```
Result:
```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-56664867f7-56wbl   1/1     Running   0          28h
coredns-56664867f7-vtqvq   1/1     Running   0          28h
...
```

## Check for errors in the DNS pod 
Use the kubectl logs command to see logs for the DNS containers.

Command:
```
kubectl logs --namespace=kube-system -l k8s-app=kube-dns --tail 50 --timestamps
```
Result:
```
...
2021-11-06T01:34:48.180776263Z [WARNING] No files matching import glob pattern: custom/*.override
2021-11-06T01:34:48.377803815Z .:53
2021-11-06T01:34:48.377817615Z membershipservices-ext.wal-mart.com.:53
2021-11-06T01:34:48.377822315Z [WARNING] No files matching import glob pattern: custom/*.override
2021-11-06T01:34:48.377826215Z [INFO] plugin/reload: Running configuration MD5 = d4041eecdd46fed4806e2fa526e86ebb
2021-11-06T01:34:48.377830115Z CoreDNS-1.8.6
2021-11-06T01:34:48.377835215Z linux/amd64, go1.17, 13a9191e
...
```