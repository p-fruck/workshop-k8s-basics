# Cluster Setup

The setup is created using [k3d](https://k3d.io/).
See its installation instructions and [advanced section](https://k3d.io/stable/usage/advanced/podman/) in case of using Podman.

## OIDC

An example config for OIDC with Keycloak is commented in the k3s-config. To use OIDC, the code can be adapted and uncommented again.

## Setup

```bash
# Change CLUSTER_DOMAIN to your cluster domain.
# Uncomment --volume to add persistent storage.
CLUSTER_DOMAIN=my.cluster.local k3d cluster create --config k3d-config.yaml # --volume "$HOME/k3d-storage:/var/lib/local-storage@all"
```

Install [flux](https://fluxcd.io/flux/installation/) CLI locally and bootstrap flux for gitops.

Using Dev Installation (not recommended for production):

```bash
kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

Also, the Gateway API CRDs must be installed by hand:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
```

Then configure this repo to be used via GitOps:

```bash
kubectl apply -k ./gitops/workshop-system/
```

This should ensure all components inside `./gitops` are applied automatically

## Cert Manager

Cert Manager can be used to properly handle certificates, e.g. using letsencrypt. This repo contains a sample setup for cert-manager + cloudflare + letsencrypt.

To configure certmanager:

```bash
k apply -k ./gitops/cert-manager
```

Add cloudflare secret

```bash
kubectl create secret generic cloudflare-api-token-secret \
  --from-literal=api-token=<YOUR_CLOUDFLARE_TOKEN> \
  --namespace cert-manager
```

Then change the details in `ClusterIssuer_letsencrypt-dns.yaml` and apply it using `kubectl apply`
