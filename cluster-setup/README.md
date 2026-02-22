# Cluster Setup

The setup is created using [k3d](https://k3d.io/).
See its installation instructions and [advanced section](https://k3d.io/stable/usage/advanced/podman/) in case of using Podman.

```
export CLUSTER_DOMAIN=my.cluster.local
k3d cluster create --config k3d.yaml
```

Install [flux](https://fluxcd.io/flux/installation/) CLI locally and bootstrap flux for gitops.

Using Dev Installation (not recommended for production):

```
kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

Then configure this repo to be used via GitOps:

```bash
kubectl apply -k ./gitops/workshop-system/
```

This should ensure all components inside `./gitops` are applied automatically
