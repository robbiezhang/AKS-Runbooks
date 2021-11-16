# AKS CoreDNS Custom Configurations

References:

[Autoscale the DNS Service in a Cluster
](https://kubernetes.io/docs/tasks/administer-cluster/dns-horizontal-autoscaling/)

[Customizing DNS Service
](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/#coredns)

[CoreDNS Manual](https://coredns.io/manual/toc/)

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

### Explanations of the configuration above:
- Server Block:
  
  Each Server Block starts with the zones the Server should be authoritative for. After the zone name or a list of zone names (separated with spaces), a Server Block is opened with an opening brace. A Server Block is closed with a closing brace. The AKS default Server Block serves the root zone: '.'. ":53" means it serves the request on port 53.

- Plugins:

  Each Server Block specifies a number of plugins that should be chained for this specific Server. The definition of the plugins can be found [here](https://coredns.io/plugins/).

  The most important plugin in the AKS default Server Block is the [kubernetes](https://coredns.io/plugins/kubernetes/) plugin. It handles all queries in the "cluster.local" zone and 2 "reverse dns lookup" zones.

- Customization hooks

  We added the 2 hooks in the coredns configuration to allow customization.

  **import custom/*.override**: allow adding plugin in the default Server Block.

  **import custom/*.server**: allow adding Server Blocks.

  This is implemented by mounting the coredns-custom configmap into the /etc/coredns/custom folder, and use [import](https://coredns.io/plugins/import/) plugin to include files into the main configuration.

  coredns-custom config is empty by default. We allows customer to edit this configmap to achieve the customization of the coredns configuration.

### Examples:
- Enable log

    The [log](https://coredns.io/plugins/log/) plugin enables query logging to the standard output.
    Apply [coredns-custom-log.yaml](coredns-custom-log.yaml)

    ```
    kubectl patch cm coredns-custom -n kube-system --patch-file coredns-custom-log.yaml
    ```
    Since we have the [reload](https://coredns.io/plugins/reload/) plugin in the configuration, the change will be reloaded automatically within 1 min.

    Command:
    ```
    kubectl -n kube-system logs -l k8s-app=kube-dns --timestamps
    ```

    Result:
    ```
    [INFO] Reloading
    [WARNING] No files matching import glob pattern: custom/*.server
    [WARNING] No files matching import glob pattern: custom/*.server
    [INFO] plugin/reload: Running configuration MD5 = bc7626f6210a5c421855f7722e2a517e
    [INFO] Reloading complete
    ```

    Command:
    ```
    kubectl exec dnsutils -- nslookup kubernetes
    ```
    CoreDNS log:
    ```
    [INFO] 10.244.1.12:41045 - 64252 "A IN kubernetes.default.svc.cluster.local. udp 54 false 512" NOERROR qr,aa,rd 1060.000375798s
    [INFO] 10.244.1.12:45056 - 52140 "AAAA IN kubernetes.default.svc.cluster.local. udp 54 false 512" NOERROR qr,aa,rd 147 0.000303199s
    ```

    Command:
    ```
    kubectl exec dnsutils -- nslookup kubernetes.
    ```
    CoreDNS log:
    ```
    [INFO] 10.244.1.12:42451 - 17013 "A IN kubernetes. udp 28 false 512" NXDOMAIN qr,rd,ra 103 0.007624855s
    ```

- Add Stub Domain

    Sometimes, customer wants to handle the DNS query to a particular zone specially. They can add a stub domain to achieve it.

    Apply [coredns-stub-domain.yaml](coredns-stub-domain.yaml)

    ```
    kubectl patch cm coredns-custom -n kube-system --patch-file coredns-stub-domain.yaml
    ```

    Same as above, the reload plugin will reload the change within 1 min.

    Command:
    ```
    kubectl exec dnsutils -- nslookup google.com.
    ```

- Rewrite DNS query

    The [rewrite](https://coredns.io/plugins/rewrite/) plugin can manipulate the DNS query.

    Apply [coredns-rewrite.yaml](coredns-rewrite.yaml)

    ```
    kubectl patch cm coredns-custom -n kube-system --patch-file coredns-rewrite.yaml
    ```

    Command:
    ```
    kubectl exec dnsutils -- nslookup kubernetes.non.existent.
    ```
    Result:
    ```
    Server:         10.0.0.10
    Address:        10.0.0.10#53

    Name:   kubernetes.non.existent
    Address: 10.0.0.1
    ```

    Remove the "anwser" from the rewrite plugin to see what's the difference in the response.

### Notice:
1. You cannot define the same Server Block (same zone on same port) more than once.
2. You cannot include the same plugin more than once in the same Server Block
3. The order of the plugins is not determined by the order in the configuration. The ordering is defined in the [plugin.cfg](https://github.com/coredns/coredns/blob/master/plugin.cfg)
