# About CoreDNS

[CoreDNS](https://coredns.io/) is a flexible, extensible DNS server that can serve as the Kubernetes cluster DNS. CoreDNS project is hosted by the CNCF.

[CoreDNS Codebase](https://github.com/coredns/coredns)

[CoreDNS Release Note](https://coredns.io/tags/release/)

# Service in Kubernetes

Service is an abstract way to expose an application running on a set of Pods as a network service.
With Kubernetes you don't need to modify your application to use an unfamiliar service discovery mechanism. Kubernetes gives Pods their own IP addresses and a single DNS name for a set of Pods, and can load-balance across them.

[Kubernetes DNS specification](https://github.com/kubernetes/dns/blob/master/docs/specification.md)

## DNS for Services and Pods
CoreDNS watches the Kubernetes API for new Services and creates a set of DNS records for each one. If DNS has been enabled throughout your cluster then all Pods should automatically be able to resolve Services by their DNS name.

## Hands on Lab

Samples:
- [x] DNS utilities: [dnsutils.yaml](dnsutils.yaml)
- [x] nginx: [nginx-deploy.yaml](nginx-deploy.yaml)

0. Cluster DNS IP
    ```
    kubectl get svc -n kube-system kube-dns
    ```
    Result:
    ```
    NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)         AGE
    kube-dns   ClusterIP   10.0.0.10    <none>        53/UDP,53/TCP   2d
    ```

1. Create the DNS utils pod
    ```
    kubectl apply -f dnsutils.yaml
    ```
    Result:
    ```
    pod/dnsutils created
    ```
    
2. Verify dnsutils is running
    ```
    kubectl get po dnsutils
    ```
    Result:
    ```
    NAME       READY   STATUS    RESTARTS   AGE
    dnsutils   1/1     Running   0          40s
    ```
3. Test the kubernetes DNS
    ```
    kubectl exec dnsutils -- nslookup kubernetes
    ```
    Result:
    ```
    Server:         10.0.0.10
    Address:        10.0.0.10#53

    Name:   kubernetes.default.svc.cluster.local
    Address: 10.0.0.1
    ```

4. Check the pod's DNS config
    ```
    kubectl exec dnsutils -- cat /etc/resolv.conf
    ```
    Result:
    ```
    search default.svc.cluster.local svc.cluster.local cluster.local ke1dvxqedaou5n2npkso3d0wfd.xx.internal.cloudapp.net
    nameserver 10.0.0.10
    options ndots:5
    ```
5. Create nginx deployment in "test" namespace
    ```
    kubectl create ns test
    kubectl apply -f nginx.yaml -n test
    ```
    Result:
    ```
    namespace/test created
    deployment.apps/nginx created
    ```
6. Check nginx pods are running
    ```
    kubectl get po -n test
    ```
    Result:
    ```
    ```
7. Expose nginx service
    ```
    kubectl expose deploy/nginx -n test
    ```
    Result:
    ```
    service/nginx exposed
    ```
8. Check the nginx service
    ```
    kubectl get svc nginx -n test
    ```
    Result:
    ```
    NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    nginx               ClusterIP   10.0.61.32   <none>        80/TCP    90s
    ```
9.  Test nginx DNS
    ```
    kubectl exec dnsutils -- nslookup nginx
    ```
    Result:
    ```
    Server:         10.0.0.10
    Address:        10.0.0.10#53

    ** server can't find nginx: NXDOMAIN
    ```
    **Why?**
10. 