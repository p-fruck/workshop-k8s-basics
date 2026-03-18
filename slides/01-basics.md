---
title: "K8s Workshop: **Getting started**"
author: Philipp Fruck
options:
  end_slide_shorthand: true
---

First steps
===

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
# Questions
- What cluster am I on?
- Which user am I?
- Which groups do I have?
- How many nodes do I have?
- Which k8s version(s) am I running?

<!-- pause -->
## Who am I

```bash +no_background
# account & groups
kubectl auth whoami
# permissions
kubectl auth can-i --list
```

<!-- column: 1 -->
<!-- pause -->
## Nodes

```bash +no_background
# list all cluster nodes
kubectl get nodes
# plural and singular do work
kubectl get node
```
<!-- pause -->
## More Node Info
```bash +no_background
kubectl get nodes -o wide
kubectl describe nodes [node]
```

---
Resources
===

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
Everything in K8s is a resource

```bash +no_background
# list all resources
kubectl api-resources
# get all namespace resources
kubectl get ns
# get one namespace resource
kubectl get ns kube-system
```
<!-- pause -->

Self-documenting
```bash
k explain ns
k explain ns.status
```

<!-- column: 1 -->
<!-- pause -->
How to output?

```bash +no_background
# human readable
k describe ns kube-system
# more detail (not for every resource)
k get ns kube-system -owide
# in yaml
k get ns kube-system -oyaml
# or json
k get ns kube-system -ojson
```

We can use `yq/jq`!

---
Namespaces
===

<!-- column_layout: [2, 3] -->
<!-- column: 0 -->
Resources can be global (nodes) or namespaced (pods)

To see available namespaces:

```bash +no_background
kubectl get namespaces
kubectl get namespace
kubectl get ns
````

Full access to 2 namespaces:
- Your username
- Your group name
<!-- column: 1 -->
<!-- pause -->
# Available Namespaces

- **kube-system**: Critical cluster components
  - e.g: `coredns`, `etcd`
- **default**: The default namespace. Don't use it :)
  - Ephemeral containers pile up here
- **ingress-system**: Ingress Controller
  - Nginx/Traefik/Caddy/HAproxy or whatever
- Further cluster wide applications
  - **flux-system**: Git-Ops
  - **cert-manager**: X509 Certificates
- Only **kube-system** and **default** come out of the box

---
Using/Switching Namespaces
===

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
# Accessing Resources

```bash +no_background
# show global resources
kubectl get nodes

# show pods in different namespaces
kubectl get pods -n ingress-system
kubectl get pods -n kube-system

# show pods in all namespaces
# (that you have access to)
kubectl get pods -A
```
  
<!-- column: 1 -->
# Switching Namespaces

```bash +no_background
# switch my default namespace
kubectl config set-context --current \
  --namespace=<your-namespace>
# or with kubectx installed
kubectl ns your-namespace
# show current namespace
kubectl ns -c

# Side note: Switch cluster context
# when working with multiple clusters
kubectl ctx [-c]
```

---
Pods
===

<!-- column_layout: [4, 3] -->
<!-- column: 0 -->
## What is a Pod

The smallest deployable unit in Kubernetes is a **Pod**.

A pod contains:
- one or more containers
  - possibly init-containers
- shared network
- possibly shared storage

Think of a pod as: "one logical application unit"

Often: 1 Pod = 1 Container

<!-- column: 1 -->
## Example Manifest

```file +no_background +line_numbers
path: ../examples/01-basics/pod.yaml
language: yaml
start_line: 2
```

---
Launching a Pod
===

<!-- column_layout: [4, 3] -->
<!-- column: 0 -->
Lets create your first pod!

```bash
k apply -f examples/01-basics/pod.yaml
```

<!-- pause -->
And now?
<!-- pause -->

```bash
k get pods
k describe pod nginx-pod
k logs -f nginx-pod
k exec -it nginx-pod -- ash
```

<!-- column: 1 -->
<!-- pause -->
# How to stop it

Inside the container:
- ps
- `kill 1`

Is it dead?
<!-- pause -->
No it's restarted!

`k delete pod nginx-pod`

---
Metadata
===

- The `.metadata` Object contains e.g. `name` of the pod
- `namespace` Can be specified to define a pod namespace
  - If omitted: Current namespace
- `labels`: Identifying metadata
  - Key-value pairs used for selection, grouping, filtering
- `annotations`: Non-Identifying metadata
  - Key-value pairs used for Tooling/URLs/Info
- `uid`: Unique ID assigned by the Kubernetes API server
- `resourceVersion`: Internal version to track changes for optimistic concurrency
- `generation`: Tracks changes in the spec (not metadata)
- `finalizers`: List of controllers that must finish cleanup before deletion
- ... and more (`kubectl explain pod.metadata`)

---
Labels Example
===

```file +no_background +line_numbers
path: ../examples/01-basics/pod-labels.yaml
language: yaml
start_line: 2
end_line: 13
```

<!-- reset_layout -->
> https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/

---
Deployment Models
===
Pods are usually **not managed directly**. Instead, we use abstractions:

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->

# Deployment
- Most common. Manages stateless pods, rolling updates, scaling
- Example: Web App, API server, ...
<!-- pause -->
# DaemonSet
- Ensures one pod runs on every node (or a subset via nodeSelector)
- Use case: logging agents, monitoring agents, network proxies
<!-- column: 1 -->
<!-- pause -->
# StatefulSet
- For stateful apps needing stable network IDs & persistent storage
- Example: Databases (Postgres, MongoDB), Kafka
- Maintains pod order, stable hostnames, persistent volumes
<!-- pause -->
# ReplicaSet (rare to use directly)
- Ensures a number of pod replicas
- Deployment -> ReplicaSet -> Pod(s)

---
Deployment
===

<!-- column_layout: [3, 4] -->
<!-- column: 0 -->
```file +no_background +line_numbers
path: ../examples/01-basics/deployment.yaml
language: yaml
start_line: 2
end_line: 17
```
<!-- column: 1 -->
<!-- pause -->
```bash +no_background
# apply the deployment
k apply -f examples/01-basics/deployment.yaml
# show deployments:
k get deploy
# now: scale down
k scale deploy nginx-deployment --replicas=2
# delete one pod - will it come back?
k delete pod nginx-deployment-<rev>-<id>
# upgrade image of container nginx
k set image deployment/nginx-deployment nginx=nginx:1.29-alpine
# some problem occured! undo the upgrade!
k rollout undo deploy/nginx-deployment
# or just restart if needed
k rollout restart deploy/nginx-deployment
```
