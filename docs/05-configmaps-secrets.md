# 05 — ConfigMaps & Secrets

## Why they exist

Hardcoding config inside a Pod manifest is bad:
- You'd need different YAML files for dev/staging/prod
- Secrets (passwords, keys) would be visible in plain text in your repo

ConfigMaps and Secrets solve this by storing config **outside the Pod**, injected at runtime.

| | ConfigMap | Secret |
|---|---|---|
| For | Non-sensitive config | Sensitive data |
| Stored as | Plain text | base64-encoded |
| Examples | URLs, feature flags, region | Passwords, API keys, tokens |

---

## ConfigMap (`manifests/05-configmap.yaml`)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  APP_ENV: "production"
  APP_REGION: "eastus"
  MAX_CONNECTIONS: "100"
```

Just key-value pairs. Nothing special. Referenced by name from the Deployment.

---

## Secret (`manifests/06-secret.yaml`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nginx-secret
type: Opaque
stringData:
  DB_PASSWORD: "super-secret-password"
  API_KEY: "abc123xyz"
```

`stringData` lets you write plain text — Kubernetes base64-encodes it automatically when stored.
`type: Opaque` = generic secret (other types exist for TLS certs, Docker credentials, etc.)

**Important:** Secrets are base64-encoded, NOT encrypted by default in K8s.
In AKS you should enable encryption at rest for etcd in production.

---

## How they're injected into the Deployment

```yaml
env:
  # From ConfigMap
  - name: APP_ENV
    valueFrom:
      configMapKeyRef:
        name: nginx-config    # ConfigMap name
        key: APP_ENV          # Key inside the ConfigMap

  # From Secret
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: nginx-secret    # Secret name
        key: DB_PASSWORD      # Key inside the Secret
```

Inside the container, these become normal environment variables:
`echo $APP_ENV` → `production`
`echo $DB_PASSWORD` → `super-secret-password`

---

## Apply order matters

ConfigMap and Secret must exist **before** the Deployment that references them.

```bash
# 1. Create ConfigMap first
kubectl apply -f manifests/05-configmap.yaml

# 2. Create Secret
kubectl apply -f manifests/06-secret.yaml

# 3. Then update the Deployment
kubectl apply -f manifests/04-deployment-nginx.yaml

# Verify env vars are injected into a pod
kubectl exec -it <pod-name> -- env | grep -E "APP_ENV|DB_PASSWORD"
```

---

## Useful commands

```bash
# See all configmaps
kubectl get configmaps
kubectl get cm                        # shorthand

# See configmap contents
kubectl describe cm nginx-config

# See all secrets
kubectl get secrets

# See secret (values are base64-encoded)
kubectl describe secret nginx-secret

# Decode a secret value manually
kubectl get secret nginx-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode
```
