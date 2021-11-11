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

In the kubes-sytem namespace, there are 2 configmaps created by default for coredns: coredns and coredns-custom

