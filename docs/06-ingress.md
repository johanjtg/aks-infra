# 06 — Ingress

## Why Ingress?

Before Ingress, each Service needed its own `LoadBalancer` = its own public IP = costs money.

| Before | After Ingress |
|---|---|
| nginx → public IP #1 | nginx → Ingress → public IP (shared) |
| python-app → public IP #2 | python-app → Ingress → same public IP |
| N services = N public IPs | N services = 1 public IP |

Ingress also adds URL-based routing — something LoadBalancer alone can't do.

---

## Two parts

### 1. Ingress Controller
A reverse proxy running inside the cluster. Installed once via Helm. Owns the single public IP.

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=1
```

### 2. Ingress Resource
Your YAML routing rules — tells the controller where to send traffic.

---

## The manifest (`manifests/07-ingress.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  number: 80
```

### Adding more services later (e.g. your Python app)

```yaml
rules:
  - http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: nginx-service
              port:
                number: 80
        - path: /api
          pathType: Prefix
          backend:
            service:
              name: python-app-service
              port:
                number: 8000
```

---

## Service type change

With Ingress handling the public IP, individual Services no longer need `LoadBalancer`.
Changed `nginx-service` from `LoadBalancer` → `ClusterIP` (internal only).

```
Before:  Internet → nginx-service (LoadBalancer, public IP)
After:   Internet → Ingress Controller (public IP) → nginx-service (ClusterIP, internal)
```

---

## How traffic flows

```
User browser
    │
    ▼
172.199.58.131 (Ingress Controller public IP)
    │
    │  path: /
    ▼
nginx-service (ClusterIP — internal only)
    │
    ├──▶ Pod 1 (nginx)
    ├──▶ Pod 2 (nginx)
    └──▶ Pod 3 (nginx)
```

---

## Useful commands

```bash
# See the ingress and its address
kubectl get ingress

# See the ingress controller's public IP
kubectl get svc -n ingress-nginx

# Test the ingress (use the EXTERNAL-IP from above)
curl http://172.199.58.131

# Describe ingress for routing details
kubectl describe ingress main-ingress

# See ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```
