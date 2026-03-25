---
title: "K8s Workshop: **Packaging**"
author: Philipp Fruck
options:
  end_slide_shorthand: true
---

Shipping Apps on Kubernetes
===


# Problem Statement

<!-- incremental_lists: true -->
- We know how to deploy an app using Deployments, Services, etc.
- Does this suffice?
  - How do we package apps?
  - How can we version them?
  - How can we distribute the packaged apps?
  - How do we make deployments **repeatable**?
    - Same app across test/ref/prod with different settings?

---
Improvement
===
<!-- column_layout: [1,1] -->
<!-- column: 0 -->
# Baseline

We wrote raw Kubernetes manifests

```bash +no_background
├── test/
│   ├── deployment.yaml
│   ├── ingress.yaml
│   └── service.yaml
└── prod/
    ├── deployment.yaml
    ├── ingress.yaml
    └── service.yaml
```
<!-- column: 1 -->
# Goal

We want to
<!-- incremental_lists: true -->
- Change replicas per env
- Change the image tag
- Share this with another team
- Track changes

---
Kustomize
===

[Kustomize](https://kustomize.io) is K8s native configuration management
- Template-free
- Nowadays: Built into `kubectl`
  - Use `kubectl apply -k <path>` instead of `-f`
  - Or to preview: `kubectl kustomize <path>`
- Idea:
  - Start with a base (Deployment, Service, ...)
  - Create overlays (one per environment)
  - Use Overlay to customize the app
    - Patches
    - Transformers

---
Base Kustomization
===

<!-- column_layout: [3,5] -->
<!-- column: 0 -->
# Layout
```bash +exec +no_background
tree -C ../examples/04/my-app
```

<!-- column: 1 -->
<!-- pause -->
## Kustomization
```file +no_background +line_numbers
path: ../examples/04/my-app/base/kustomization.yaml
language: yaml
title: Test
```

<!-- pause -->
```bash +no_background
kubectl kustomize examples/04/my-app/base/
```

---
Overlays
===

The kustomization for the prod overlay looks like this:
<!-- column_layout: [3,5] -->
<!-- column: 0 -->

```file +no_background +line_numbers
path: ../examples/04/my-app/overlays/prod/kustomization.yaml
language: yaml
end_line: 13
```
<!-- column: 1 -->
```file +no_background +line_numbers
path: ../examples/04/my-app/overlays/prod/kustomization.yaml
language: yaml
start_line: 14
```

```bash +no_background
kubectl kustomize examples/04/my-app/overlays/prod/
```

---
The Diff
===

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
```bash +no_background
cd examples/04/myapp/ && diff -u \
  <(kubectl kustomize base) \
  <(kubectl kustomize overlays/prod)
```
```diff +no_background
 apiVersion: v1
 kind: Service
 metadata:
-  name: nginx
+  labels:
+    env: prod
+  name: prod-nginx
 spec:
   selector:
     app: nginx
+    env: prod
```

<!-- column: 1 -->
```diff +no_background
 apiVersion: apps/v1
 kind: Deployment
 metadata:
-  name: my-nginx
+  labels:
+    env: prod
+  name: prod-my-nginx
 spec:
-  replicas: 1
+  replicas: 2
   template:
     spec:
       containers:
-      - image: nginx:alpine
+      - image: nginx:1.29-alpine
```

---
Kustomize
===

# Conclusion

- Overlay = environment
- No templating → "safer", predictable
- But:
  - Hard to reuse across teams
  - No packaging/distribution story
  - More complicated than templating (?)

---
Helm
===

<!-- column_layout: [3,2] -->
<!-- column: 0 -->
# What is it?
- [Helm](htpps://helm.sh)
- Package manager for Kubernetes
  - Simplifies sharing applications
## Key Concepts
- **Repo** → registry holding your chart
  - Can also be the container registry
- **Chart** → packaged app (YAML templates)
- **Release** → deployed instance of a chart
- **Values** → configuration (overrides)

<!-- column: 1 -->
## Why use Helm?
- Reusable deployments
- Easy upgrades & rollbacks
- Environment-specific configs
- Templates instead of Overlays

---
Basic Helm Workflow
===

```bash
helm repo add <repo>
helm install my-app <chart>
helm upgrade my-app <chart>
helm uninstall my-app
```

---
Create a Chart
===
<!-- column_layout: [1,1] -->
<!-- column: 0 -->

# Init

```bash +no_background
helm create demo-api
cd demo-api
```

## Cleanup

```bash +no_background
rm templates/hpa.yaml templates/tests/*
```
<!-- column: 1 -->

## values.yaml

```yaml +no_background
replicaCount: 2

image:
  repository: ghcr.io/example/demo-api
  tag: "1.0.0"

service:
  port: 80
  targetPort: 8080
```


---
Commands
===

<!-- column_layout: [3,2] -->
<!-- column: 0 -->
# Local

```bash +no_background
# Dry-run
helm template .

# Add values
helm template . [-f/--values values-dev.yaml]

# Run unit/integration tests
helm test .
```

<!-- column: 1 -->
# Cluster
```bash +no_background
# Install
helm install demo ./demo-api

# Override values:
helm install demo ./demo-api \
  --set replicaCount=1 \
  --set image.tag=dev

# Upgrade
helm upgrade demo ./demo-api
```

---
Hooks
===
<!-- column_layout: [1,1] -->
<!-- column: 0 -->

# What are Hooks?
- Lifecycle triggers for Helm releases
- Run custom Kubernetes resources at specific events

## When they run
- pre-install / post-install
- pre-upgrade / post-upgrade
- pre-delete / post-delete
- pre-rollback / post-rollback
<!-- column: 1 -->

## How they work
- Defined via annotations:
  "helm.sh/hook": pre-install
- Typically used with Jobs or Pods

## Common Use Cases
- DB migrations before deploy
- Cleanup tasks on uninstall
- Health checks after install

## Why use them?
- Extend Helm beyond templating
- Control deployment workflow precisely

---
Helm Conclusion
===

- Helm = **distribution format**
- Can publish charts to registries
- Strong ecosystem
- Quick and easy installation

But:

- Debugging templates can be painful
- Logic creeps into templates
- Upgrading helm charts can cause pain

---
Operators
===

# What

- Extension of Kubernetes that automates app-specific operations
- Encodes human operational knowledge into software

## Core Idea
- Uses **Custom Resource Definitions (CRDs)** + controllers
- Continuously reconciles desired vs actual state

---
Operators
===

## What Operators Do
- Install & configure apps
- Handle upgrades & backups
- Manage scaling & recovery

## Why it matters
- Automates complex stateful apps
- Reduces manual ops work
- Makes apps "self-healing"
  - On top of the default K8s self-healing mechanisms

---
# Operator Capability/Maturity Levels

![image:width:100%](../assets/operator-capability-level.png)


> https://sdk.operatorframework.io/docs/overview/operator-capabilities/

---
Example: Keycloak Operator
===

- Let's take a look at the keycloak operator in our cluster
  - Configuration: Single Keycloak Custom Resource (CR) instead of values.yaml
  - Self-documenting using `kubectl explain`
- Manages Deployment, Ingress, ...
- Handles Application Scale-down for upgrades

---
GitOps
===
<!-- column_layout: [1,1] -->
<!-- column: 0 -->

# What is GitOps?
- Operational model using Git as the single source of truth
- Infrastructure & apps defined declaratively (YAML)

## Core Principles
- **Declarative** → desired state stored in Git
- **Versioned** → full history & audit trail
- **Automated** → controllers apply changes
- **Reconciled** → cluster continuously matches Git
<!-- column: 1 -->

## How it works
1. Commit changes to Git
2. GitOps controller detects changes
3. Applies them to the cluster
4. Ensures drift is corrected

## Benefits
- Easy rollbacks (git revert)
- Improved security & auditability
- Consistent, repeatable deployments

## Popular Tools
- Argo CD
- Flux


---
Flux
===

Our cluster uses [Flux](https://fluxcd.io/)

# Key Concepts
- **GitRepository** → source of truth (Git repo)
- **Kustomization** → applies manifests from repo
- **HelmRelease** → manages Helm charts declaratively
- **Reconciliation loop** → ensures desired state = actual state
<!-- column_layout: [2,3] -->
<!-- column: 0 -->

## Pods

```bash +no_background
kubectl get pods -n flux-system
```
<!-- column: 1 -->
## Setup
- https://fluxcd.io/flux/get-started/
- Either bootstrapping or manual

---
Step 1: GitRepository
===

```yaml +no_background
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: myapp
spec:
  interval: 1m
  ref:
    branch: main
  # https or ssh://git@github.com...
  url: https://github.com/YOUR_ORG/demo-gitops
```

```bash +no_background
# using private repos
kubectl explain gitrepo.spec.secretRef
```

---
Step 2: Kustomization
===

```yaml +no_background
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
spec:
  interval: 30m0s
  path: ./kustomize
  prune: true
  retryInterval: 2m0s
  sourceRef:
    kind: GitRepository
    name: myapp
  targetNamespace: default
  timeout: 3m0s
  wait: true
```

---
Private Repo Auth (Manual Way)
===

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
# Create secret:

```bash +no_background
kubectl create secret \
  generic github-token \
  --from-literal=username=git \
  --from-literal=password=<PAT>
```

<!-- column: 1 -->
## Reference it:

```yaml +no_background
spec:
  secretRef:
    name: flux-system
```

<!-- reset_layout -->
## Why Username/Password
- I still recommend SSH Keys for better security
- But: PAT can be reused to clone repo and as image pull secret
  - Easier for testing, but don't get used to it

---
CLI Commands
===

- Resources can be manages via `kubectl get gitrepo/ks/hr`

```bash +no_background
flux reconcile kustomization <name> [flags]
flux reconcile source git <name> [flags]
# Reconciles the source first, then the Kustomization
# Forces a reconciliation, useful for re-applying resources (helm hooks)
flux reconcile kustomization my-app --with-source --force
# pause and resume a kustomization
flux suspend kustomization my-app
flux resume kustomization my-app
```
