# Headless Service in Kubernetes

[Reference](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)

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



lab:
1. headless svc with ready/not-ready pods
2. headless svc with publishNotReadyAddresses