---
title: "K8s Workshop: **Services**"
author: Philipp Fruck
options:
  end_slide_shorthand: true
---

Problem Statement
===
<!-- column_layout: [1,1] -->
<!-- column: 0 -->
# What we have

- Interact with K8s
- Spawn Pods
- Manage Pod Lifecycle

<!-- column: 1 -->
# What we lack
- Actually reaching our Pod
  - Discovery?
- Loadbalancing
- Failover

---
Dynamic Discovery
===
<!-- column_layout: [3,2] -->
<!-- column: 0 -->

Remember what I told you about about coredns?
<!-- pause -->
- DNS resolution of pods is enabled automatically
  - But How? Using pod name? Fully randomized!
<!-- pause -->
- Solution: Create a **Service**
  - Stable network endpoint for a set of pods
  - `<service>.<namespace>.svc.cluster.local`
  - Or just `service` in the same namespace
<!-- pause -->
```bash +no_background
# apply the service
kubectl apply -f examples/02-services/svc.yml
# show service and endpoints
kubectl get svc
kubectl get endpointslice
```

<!-- column: 1 -->
```file +no_background +line_numbers
path: ../examples/02-services/svc.yml
language: yaml
start_line: 2
end_line: 17
```

---
Service Types
===


| Type                    | Purpose                                                                        |
| ----------------------- | ------------------------------------------------------------------------------ |
| **ClusterIP** (default) | Exposes service **inside the cluster** only. Pods can reach it via DNS.        |
| **NodePort**            | Exposes service at a static port on every node (external access).              |
| **LoadBalancer**        | Uses cloud provider to create an **external load balancer**.                   |
| **ExternalName**        | Maps service to an **external DNS name**.                                      |

Confusion: All services perform cluster-internal loadbalancing between the matched pods

---

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
Ingress
===

- Handles ingress to the cluster
  - Like one big reverse proxy
  - Describes where to send traffic
  - Ingress -> Service -> Endpoints
- Handles by the ingress-controller
  - Must be installed first
  - Multiple controllers can exist
    - `kubernetes.io/ingress.class`
- Usually OSI L7
  - Some controllers support L4
    - But: No standard
<!-- pause -->
- [Gateway API](gateway-api.sigs.k8s.io)
  - More modern, kind of successor
  - Supports L4!
  - But: "More complicated"

<!-- column: 1 -->
<!-- pause -->
```file +no_background +line_numbers
path: ../examples/02-services/ingress.yml
language: yaml
start_line: 2
```

---
Cool!
===
<!-- pause -->
Where TLS???
===

---
Issuer
===

Typically used with cert-manager, issuers define how TLS certs get issued
<!-- column_layout: [1,1] -->
<!-- column: 0 -->
# Issuer
- Namespace-scoped
  - Only works within this namespace
- Good for: per-team or isolated setups
<!-- column: 1 -->
# Cluster Issuer
- Cluster-wide
- Can be used by any namespace
- Good for: shared, central certificate management

---
Ingress TLS
===
<!-- column_layout: [6,7] -->
<!-- column: 0 -->
With an issuer configured, we can add the following config to the ingress:
- Cert-manager annotation: Tells cert-manager which issuer to use
- `.spec.tls` adds a HTTPS host
  - Same name as HTTP host
  - `secretName` is the name of the secret that will be populated

```bash +no_background
# apply (patch) partially valid file
kubectl apply --server-side \
  -f examples/ingress-tls.yaml
```
<!-- column: 1 -->
```file +no_background +line_numbers
path: ../examples/02-services/ingress-tls.yml
language: yaml
start_line: 2
```

---
I want to see LB!
===

<!-- column_layout: [4,7] -->
<!-- column: 0 -->
Can we visualize load balancing?

Patch the nginx to show its hostname.

```bash +no_background
cd examples/02-services
k apply -f nginx-host.yml
```


<!-- column: 1 -->
Deployment `.spec.template.spec`:

```file +no_background +line_numbers
path: ../examples/02-services/nginx-host.yml
language: yaml
start_line: 17
```
