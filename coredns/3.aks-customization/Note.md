# AKS CoreDNS Custom Configurations

References:

[Autoscale the DNS Service in a Cluster
](https://kubernetes.io/docs/tasks/administer-cluster/dns-horizontal-autoscaling/)

[Customizing DNS Service
](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/#coredns)

[Customize CoreDNS with Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/coredns-custom)

---
## DNS Autoscaling
We adopt the k8s DNS horizontal autoscaling solution, which uses the cluster-proportional-autoscaler with default ladder:
```
{"ladder":{"coresToReplicas":[[1,2],[512,3],[1024,4],[2048,5]],"nodesToReplicas":[[1,2],[8,3],[16,4],[32,5]]}}
```

We allow customer to tune the ladder by editing coredns-autoscaler configmap in kube-system namespace.

Try apply [coredns-autoscaler-1.yaml](coredns-autoscaler-1.yaml) and [coredns-autoscaler-3.yaml](coredns-autoscaler-3.yaml) to see the scaling of the coredns pods.

## AKS Customization
CoreDNS is a DNS server that is modular and pluggable, and each plugin adds new functionality to CoreDNS. In AKS, we provide a default Corefile, and hooks 2 integration points for customization.

The Corefile is defined in the coredns configmap in the kube-system namespace, and we reconcile the setting to ensure the basic cluster DNS configuration is expected. Here is the content:
```
data:
  Corefile: |
    .:53 {
        errors
        ready
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
        import custom/*.override
    }
    import custom/*.server
```

**import custom/*.override**: allow adding plugin in the default section.
**import custom/*.server**: allow adding stub-domain overrides.

coredns-custom is empty by default. We allows customer to edit this configmap to achieve the customization of the coredns configuration.

Examples:
### Enable log
Apply [coredns-custom-log.yaml](coredns-custom-log.yaml)

```
kubectl patch cm coredns-custom -n kube-system --patch-file coredns-custom-log.yaml
```

### Add Stub Domain