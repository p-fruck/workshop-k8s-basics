---
title: "K8s Workshop: **Security Concepts**"
author: Philipp Fruck
options:
  end_slide_shorthand: true
---

Kubernetes Security Concepts
===

- We know how to ship and maintain our application
  - But we have not learned how to secure/restrict it
- This session will cover:
  - Container resource management
  - **Security Context** for Pods and Containers
  - **RBAC** for K8s resources
  - **Network Policies**
  - **Policy Enforcement** = Best Practices for your cluster

---
Resources
===

# Why we should use Container Resources & Limits
- Prevent a container from **hogging CPU or memory**  
- Ensure fair **resource allocation** in multi-tenant clusters  
- Improve **stability and predictability**  
<!-- column_layout: [1,1] -->
<!-- pause -->
<!-- column: 0 -->
## Requests

- Minimum guaranteed resources
- Used by scheduler to place pods

```yaml +no_background
# Pod.spec.containers[0]
resources:
  requests:
    cpu: "500m"      # 0.5 CPU cores
    memory: "256Mi"  # 256 MiB RAM
```
  
<!-- column: 1 -->
<!-- pause -->
## Limits
- Maximum resources a container can use
- Memory limit exceeded → OOMKilled
- CPU limit exceeded → throttled

```yaml +no_background
resources:
  limits:
    cpu: "1"         # 1 CPU core max
    memory: "512Mi"  # 512 MiB max
```
  

---
Security Context
===
- Defines **permissions, capabilities, and access** at container/pod level
- Key settings:
  - `runAsUser` / `runAsGroup`
  - `fsGroup` (file system permissions)
  - `readOnlyRootFilesystem`  
  - Linux capabilities (`add` / `drop`)
  - `seLinuxOptions` / `seccompProfile`  

---
Example Context
===
<!-- column_layout: [1,1] -->
<!-- column: 0 -->

```yaml +no_background
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    image: nginx
    securityContext:
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
````
<!-- column: 1 -->
# Pod Security Context
- Defined at the pod level (spec.securityContext) in the Pod spec
- Pod-wide default
  - Baseline security context
  - Shared across container

## Container Security Context
- Can override pod-level settings
- Container-specific
  - Fine-grained control within pod

---
RBAC Basics
===

- RBAC = **Role-Based Access Control**
- Controls **who can do what** in the cluster
- Key components:

  1. **Role** – Namespaced permissions
  2. **ClusterRole** – Cluster-wide permissions
  3. **RoleBinding** – Binds a Role to users/groups within a namespace
  4. **ClusterRoleBinding** – Binds a ClusterRole to users/groups cluster-wide
- RBAC is **additive**: a user/group can have multiple roles

---
Roles
===

<!-- column_layout: [7,6] -->
<!-- column: 0 -->
**Role** example (namespace `default`):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```
<!-- column: 1 -->
# Description
- permissions within a namespace
- collection of rules
- `apiGroups`:
  - `[""]` for pods, services, ...
  - `["apps"]` for deployments
  - Respective apiVersion, e.g. `["rbac.authorization.k8s.io"]`
- `verbs`:
  - Safe: `get`, `list`, `watch`
  - Unsafe: `create`, `delete`
  - Admin: `bind`, `impersonate`

---
RoleBindings
===

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
**RoleBinding** example (bind user to Role):

```yaml +no_background
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: default
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role # Or ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```
<!-- column: 1 -->
# Description
- Maps Role to Subject(s)
- `subjects`: Who gets the permissions
  - `kind` = User, Group, ServiceAccount
  - `name` = Name of User, Group or SA
  - `namespace` = required only for SA
- `roleRef`:
  - Maps a single Role
  - Can be namespaced or global
  
---
Cluster-wide
===

- There are also ClusterRoles & ClusterRoleBindings
  - Same Syntax, only different `kind`
  - **ClusterRole** can be **used in multiple namespaces** or cluster-wide
  - **ClusterRoleBindings** ensures cluster-wide RBAC for subjects
    - Namespaces can add to that
- **RBAC: Always additive, default: Deny all**

---
ServiceAccounts
===

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
- **ServiceAccounts (SA)** = Pod Identities
- Useful for **programmatic access** to API
  - e.g. Operators, Flux, ...
- Bind SAs to Roles / ClusterRoles

Example:

```yaml +no_background
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: default
```
<!-- column: 1 -->

RoleBinding for SA:

```yaml +no_background
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sa-pod-reader
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---
Network Policies Overview
===

- Network Policies (NetPols) **restrict pod-to-pod traffic**
- Two types:

  1. **Namespaced** – only affects pods in that namespace
  2. **Cluster-wide / global** – can affect all namespaces (via CNI-specific mechanisms)
- Define **allowed ingress/egress traffic**
- Default behavior: all traffic allowed unless a NetPol exists
  - Create an empty NetPol matching all Pods for default deny
- Requires CNI that support Network Policies, e.g. Calico

---
Namespaced Network Policy
===

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
```yaml +no_background
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-postgres
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: backend
    ports:
    - protocol: TCP
      port: 5432
```

<!-- column: 1 -->
# Explanation
- Target pods:
  - podSelector selects pods labeled app=postgres → the database pods.
- `from` uses podSelector
  - allow only `role=backend` pods
- Policy type: Ingress/Egress
- Effect:
  - Only backend pods can talk to PostgreSQL pods on port 5432
  - Any other pod: denied
  - Stateful (conntrack): Traffic can flow back implicitly

---
Global NetworkPolicy
===

<!-- column_layout: [4,3] -->
<!-- column: 0 -->
- Some CNIs support cluster-wide policies via `NamespaceSelector`
- Example: allow traffic only from certain namespaces
  - Rules can have `namespaceSelector` and `podSelector` to select certain pods of given namespace
- **Hint**: Use `kubectl describe` for your NetPol

<!-- column: 1 -->
```yaml +no_background
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ns-traffic
  namespace: default
spec:
  podSelector: {} # to all pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    # could have additional
    # podSelector
    - namespaceSelector:
        matchLabels:
          env: trusted
```

---
Policies
===
# What
- Policies are rules that enforce how resources should be created, updated, or deleted
- Automatic checks and enforcement beyond the built-in RBAC and NetworkPolicy
<!-- pause -->
# Why
- Ensure pods are non-root, have read-only filesystems, drop unnecessary capabilities
  - Ensure resource limits are defined
- Enforce network isolation, e.g., require NetworkPolicies
- Guarantee all resources follow your organization’s standards
  - e.g., labels, annotations, or naming conventions
- Helpful for audit and compliance:
  - Policies can generate reports and block non-compliant resources

---
Kyverno
===
<!-- column_layout: [5,6] -->
<!-- column: 0 -->

# Overview

- Kubernetes-native policy engine
- Enforce rules like:

  - Security context requirements
  - Allowed images / registries
  - Required labels / annotations
- Example: Require non-root pods
<!-- column: 1 -->
```yaml +no_background
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-non-root
spec:
  rules:
  - name: check-run-as-non-root
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Pods must not run as root"
      pattern:
        spec:
          securityContext:
            runAsNonRoot: true
```
