# Headless Service in Kubernetes

References:

[Headless Service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)

---
## what's headless service
In the previous sessions, we learned that normal service is assigned a cluster IP from the service IP range when it is created. The service DNS will be resolved to the service IP even if there is no backend pod selected by the service.

Headless service is a special type of service whose ClusterIP (.spec.clusterIP) is set to "None" explicitly.

For headless Services, a cluster IP is not allocated, kube-proxy does not handle these Services, and there is no load balancing or proxying done by the platform for them. How DNS is automatically configured depends on whether the Service has selectors defined:

**With selectors**

For headless Services that define selectors, the endpoints controller creates Endpoints records in the API, and modifies the DNS configuration to return A records (IP addresses) that point directly to the Pods backing the Service.

**Without selectors**

For headless Services that do not define selectors, the endpoints controller does not create Endpoints records. However, the DNS system looks for and configures either:

1. CNAME records for ExternalName-type Services.
2. A records for any Endpoints that share a name with the Service, for all other types.

## Hands on Lab

Samples:
- [x] [Services normal vs headless](services.yaml)
- [x] [Headless service backend pods](headless_backend_pods.yaml)
- [x] [dnsutils](dnsutils.yaml)


1. Create services
   ```
   kubectl apply -f dnsutils.yaml
   kubectl apply -f services.yaml
   ```
   Result:
   ```
   pod/dnsutils created
   service/normal-svc created\
   service/headless-svc created
   service/external-svc created
   ```

2. Test normal svc DNS
   ```
   kubectl exec dnsutils -- nslookup normal-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   Name:   normal-svc.default.svc.cluster.local
   Address: 10.0.128.201
   ```

3. Test external svc DNS
   ```
   kubectl exec dnsutils -- nslookup external-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   external-svc.default.svc.cluster.local  canonical name = www.microsoft.com.
   www.microsoft.com       canonical name = www.microsoft.com-c-3.edgekey.net.
   www.microsoft.com-c-3.edgekey.net       canonical name = www.microsoft.com-c-3.edgekey.net.globalredir.akadns.net.
   www.microsoft.com-c-3.edgekey.net.globalredir.akadns.net        canonical name = e13678.dscb.akamaiedge.net.
   Name:   e13678.dscb.akamaiedge.net
   Address: 104.71.133.164
   Name:   e13678.dscb.akamaiedge.net
   Address: 2600:1409:d000:5ae::356e
   Name:   e13678.dscb.akamaiedge.net
   Address: 2600:1409:d000:59f::356e
   ```

4. Test headless svc DNS
   ```
   kubectl exec dnsutils -- nslookup headless-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   ** server can't find headless-svc: NXDOMAIN
   ```

5. Create headless service backend pods
   ```
   kubectl apply -f headless_backend_pods.yaml
   ```
   Result:
   ```
   pod/busybox1 created
   pod/busybox2 created
   pod/busybox3 created
   ```

6. Get the pods
   ```
   kubectl get po -l aks-lab=headless -o wide
   ```
   Result:
   ```
   NAME       READY   STATUS    RESTARTS   AGE    IP            NODE                                NOMINATED NODE   READINESS GATES
   busybox1   1/1     Running   0          2m2s   10.244.0.40   aks-agentpool-22744994-vmss000000   <none>           <none>
   busybox2   0/1     Running   0          2m2s   10.244.0.41   aks-agentpool-22744994-vmss000000   <none>           <none>
   busybox3   1/1     Running   0          2m2s   10.244.0.42   aks-agentpool-22744994-vmss000000   <none>           <none>
   ```

7. Test headless svc DNS again
   ```
   kubectl exec dnsutils -- nslookup headless-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   Name:   headless-svc.default.svc.cluster.local
   Address: 10.244.0.42
   Name:   headless-svc.default.svc.cluster.local
   Address: 10.244.0.40
   ```

8. Test pod hostname.subdomain DNS
   
   Command:
   ```
   kubectl exec dnsutils -- nslookup busybox-1.headless-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   Name:   busybox-1.headless-svc.default.svc.cluster.local
   Address: 10.244.0.40
   ```

   Command:
   ```
   kubectl exec dnsutils -- nslookup busybox-2.headless-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   ** server can't find busybox-2.headless-svc: NXDOMAIN
   ```

   Command:
   ```
   kubectl exec dnsutils -- nslookup busybox-3.headless-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   ** server can't find busybox-3.headless-svc: NXDOMAIN
   ```

   Command:
   ```
   kubectl exec dnsutils -- nslookup busybox-3.wrong-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   ** server can't find busybox-3.wrong-svc: NXDOMAIN
   ```

9. Set publishNotReadyAddresses to true on the headless service

   Command:
   ```
   kubectl patch svc headless-svc -p '{"spec": {"publishNotReadyAddresses":true}}'
   ```
   Result:
   ```
   service/headless-svc patched
   ```

   Command:
   ```
   kubectl exec dnsutils -- nslookup headless-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   Name:   headless-svc.default.svc.cluster.local
   Address: 10.244.0.42
   Name:   headless-svc.default.svc.cluster.local
   Address: 10.244.0.41
   Name:   headless-svc.default.svc.cluster.local
   Address: 10.244.0.40
   ```

   Command:
   ```
   kubectl exec dnsutils -- nslookup busybox-2.headless-svc
   ```
   Result:
   ```
   Server:         10.0.0.10
   Address:        10.0.0.10#53

   Name:   busybox-2.headless-svc.default.svc.cluster.local
   Address: 10.244.0.41
   ```