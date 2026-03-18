---
title: "K8s Workshop: **Config**"
author: Philipp Fruck
options:
  end_slide_shorthand: true
---

Environment Variables
===

- Set environment variables inside pods
- Example:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-demo
spec:
  containers:
    - name: app
      image: nginx
      env:
        - name: ENVIRONMENT
          value: "production"
````

* Can also reference **ConfigMaps** or **Secrets** as env sources

---

<!-- column_layout: [1,1] -->
<!-- column: 0 -->

ConfigMaps
===

- Non-sensitive configuration
- Easy to update
- No need to rebuild image
  - Note: Restart Deployment after update!
- Map values to multiple containers
- Cleaner config compared to large pod manifest

<!-- column: 1 -->

```yaml +no_background
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "debug"
---
apiVersion: v1
kind: Pod
metadata:
  name: configmap-demo
spec:
  containers:
    - name: app
      image: nginx
      envFrom:
        - configMapRef:
            name: app-config
```

---
<!-- column_layout: [1,1] -->
<!-- column: 0 -->
ConfigMaps
===

- Can also map single values instead of entire configmap values
- Great to sharing parts of configuration with other containers

<!-- column: 1 -->
```yaml +no_background
---
apiVersion: v1
kind: Pod
metadata:
  name: configmap-demo
spec:
  containers:
    - name: app
      image: nginx
      env:
      - name: SPECIAL_LEVEL_KEY
        valueFrom:
          configMapKeyRef:
            name: special-config
            key: SPECIAL_LEVEL
```

---
<!-- column_layout: [1,1] -->
<!-- column: 0 -->
Secrets
===

# How it works

- Secrets store sensitive data (passwords, tokens)
- Content is base64 ~encrypted~ encoded
  - Secret in terms of RBAC
- When creating: Use `stringData` instead of `data` to avoid messing with base64

## Git intergration
- Keep sensitive information out of Git
- If you need it: `sops` or `SealedSecrets`
<!-- column: 1 -->
```yaml +no_background
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQ=
---
apiVersion: v1
kind: Pod
metadata:
  name: secret-demo
spec:
  containers:
    - name: app
      image: myapp
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: DB_PASSWORD
```


---
Persistent Storage
===

<!-- incremental_lists: true -->
- We had all kinds of configuration, but how do we even store data?
- Of course storage is also a Resource in K8s, but how do we use it?
  - What are the advantages and disadvantages of storage in distributed systems?
<!-- incremental_lists: false -->

<!-- column_layout: [1,4,1] -->
<!-- column: 1 -->
| StorageClass           | Description                            |
| ---------------------- | -------------------------------------- |
| `standard`             | Generic default (depends on cluster)   |
| `local-path`           | Node-local path (default in k3s/k3d)   |
| `nfs`                  | Network File System; Shared Storage    |
| `cephfs`               | Ceph cluster storage; Distributed = HA |
| `glusterfs`            | GlusterFS volumes; Similar to Ceph     |
| `csi-*`                | Cloud / container storage interface    |


---
Persistent Volume Claims (PVC)
===

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
- **PVC**: Pod-level request for storage
  - No knowledge of underlying details
  - 
- Namespace scoped
- Access Modes:
  - ReadWriteOnce (RWO)
  - ReadWriteOncePod (RWOP)
  - ReadOnlyMany (ROX)
  - ReadWriteMany (RWX)
  - Indicates how many **nodes** can mount the storage
<!-- column: 1 -->

```yaml +no_background
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-demo
spec:
  accessModes:
    - ReadWriteOnce
  # e.g. nfs, local-path, ceph...
  storageClassName: fast-storage
  resources:
    requests:
      storage: 1Gi
```
  

---

Persistent Volumes (PV)
===

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
- **PV**: Cluster-level storage resource
- Unlike a PVC (which is a request), a PV is the actual storage resource
- For non-shared storage, can also contain affinity
  - Tells the pod on which node to schedule

<!-- column: 1 -->
```yaml +no_background
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-demo
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
```

---
Mounting Storage
===

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
- Ensures pod has access to persistent storage
- Decouples storage from pod lifecycle
- Required volume and mount
  - Volume: Per pod
  - VolumeMount: Per container
- Container will only start if storage available
- Storage can only be deleted when container is removed
  - Pod -> PVC -> PV
<!-- column: 1 -->
```yaml +no_background
apiVersion: v1
kind: Pod
metadata:
  name: pvc-demo-pod
spec:
  containers:
    - name: app
      image: nginx
      volumeMounts:
        - mountPath: "/data"
          name: storage
  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: pvc-demo
```

---
<!-- column_layout: [9,7] -->
<!-- column: 0 -->
Mounting Config
===

- ConfigMaps and Secrets can be mounted as files
  - Read-only inside the container
- `config-volume` is mounted under `/etc/config-data`
  - Each key in the ConfigMap becomes a file inside that directory
- `secret-volume` is mounted under `/etc/secret`
  - Only the key `my_token` is used
  - Creates a `token` file
- This approach is often used for config files
  - E.g. `/etc/nginx/conf.d/default.conf`
```yaml +no_background
kind: ConfigMap
spec:
  default.conf: | # create multiline strings
    server {
      listen 443;
    }
```
<!-- column: 1 -->
```yaml +no_background
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
    - name: mycontainer
      image: nginx
      volumeMounts: # read-only!
        - name: config-volume
          mountPath: /etc/config-data
        - name: secret-volume
          mountPath: /etc/secret/token
          subPath: my_token
  volumes:
    - name: config-volume
      configMap:
        name: my-configmap
    - name: secret-volume
      secret:
        secretName: my-secret
```
