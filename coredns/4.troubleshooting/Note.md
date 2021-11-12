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

## Enable verbose log for CoreDNS
Add the [log.override](../3.aks-customization/coredns-custom-log.yaml) section into coredns-custom configmap in kube-system namespace

**Note**: you need to merge it with the existing config if the customer already has content in teh coredns-custom configmap.

## Use CoreDNS pod IP to resolve DNS when using nslookup
CoreDNS (kube-dns) service is a normal cluster service. It relies on the iptable rules to load balance the requests to coredns pods.

Command:
```
kubectl get pods --namespace=kube-system -l k8s-app=kube-dns -o wide
```
Result:
```
NAME                      READY   STATUS    RESTARTS   AGE    IP            NODE                                NOMINATED NODE   READINESS GATES
coredns-845757d86-9rvn6   1/1     Running   0          14h    10.244.0.43   aks-agentpool-22744994-vmss000000   <none>           <none>
coredns-845757d86-mxmkw   1/1     Running   0          3d3h   10.244.0.2    aks-agentpool-22744994-vmss000000   <none>           <none>
coredns-845757d86-vtfbz   1/1     Running   0          14h    10.244.0.44   aks-agentpool-22744994-vmss000000   <none>           <none>
```

Command:
```
kubectl exec dnsutils -- nslookup www.microsoft.com 10.244.0.2
```

## Get CoreDNS prometheus metrics

```
kubectl proxy --port=8081 &

curl http://localhost:8081/api/v1/namespaces/kube-system/pods/coredns-845757d86-9rvn6:9153/proxy/metrics
```

## tcpdump