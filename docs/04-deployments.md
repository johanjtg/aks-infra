# 04 — Deployments

## Why Deployments instead of raw Pods?

| Feature | Raw Pod | Deployment |
|---|---|---|
| Auto-restart if Pod dies | No | Yes |
| Scale to N replicas | Manual | `replicas: 3` |
| Rolling updates (zero downtime) | No | Yes |
| Rollback to previous version | No | Yes |

Raw Pods are for learning. Deployments are for everything real.

---

## The hierarchy

```
Deployment
    └── ReplicaSet  (auto-created by Deployment)
            ├── Pod
            ├── Pod
            └── Pod
```

- **You** manage the Deployment
- **Deployment** manages the ReplicaSet
- **ReplicaSet** manages the Pods

You never touch ReplicaSets or Pods directly — the Deployment handles them.

---

## The manifest (`manifests/04-deployment-nginx.yaml`)

```yaml
apiVersion: apps/v1          # Deployments live in the "apps" API group
kind: Deployment
metadata:
  name: nginx-deployment       # Name of the Deployment
  labels:
    app: nginx
spec:
  replicas: 3                  # How many Pod copies to run at all times

  selector:                    # How the Deployment finds the Pods it owns
    matchLabels:
      app: nginx               # Must match the labels in the Pod template below

  template:                    # Blueprint for each Pod the Deployment creates
    metadata:
      labels:
        app: nginx             # This label MUST match selector.matchLabels above
    spec:
      containers:
        - name: nginx
          image: nginx:1.25    # Pinned version — avoid "latest" in Deployments
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "100m"      # 0.1 CPU core minimum guaranteed
              memory: "64Mi"   # 64MB RAM minimum guaranteed
            limits:
              cpu: "250m"      # 0.25 CPU core max — Pod is throttled above this
              memory: "128Mi"  # 128MB RAM max — Pod is killed if exceeded
```

---

## Key fields explained

### `replicas: 3`
Kubernetes will always try to keep exactly 3 Pods running.
Kill one manually → it creates a new one. Node goes down → reschedules elsewhere.

### `selector.matchLabels`
This is how the Deployment knows which Pods belong to it.
**Must exactly match** the labels in `template.metadata.labels`.
If they don't match, Kubernetes will error on apply.

### `template`
This is a Pod spec embedded inside the Deployment.
Every Pod the Deployment creates will look exactly like this template.

### `resources`
| Field | Meaning |
|---|---|
| `requests` | Minimum guaranteed resources — used by scheduler to pick a node |
| `limits` | Hard ceiling — CPU is throttled, RAM excess kills the Pod |
| `100m` | Millicores — 1000m = 1 full CPU core |
| `64Mi` | Mebibytes (≈ megabytes) |

Always set resources. Without them a single runaway Pod can starve the whole node.

---

## Applying and exploring

```bash
# Deploy
kubectl apply -f manifests/04-deployment-nginx.yaml

# See the Deployment
kubectl get deployments
kubectl get deploy              # shorthand

# See the Pods it created (notice the random suffix in names)
kubectl get pods

# See the ReplicaSet it created automatically
kubectl get replicasets
kubectl get rs                  # shorthand

# Full details (events, rollout status, etc.)
kubectl describe deployment nginx-deployment

# Watch rollout progress in real time
kubectl rollout status deployment/nginx-deployment
```

---

## Scaling

```bash
# Scale to 5 replicas via kubectl (quick test)
kubectl scale deployment nginx-deployment --replicas=5

# Scale back down
kubectl scale deployment nginx-deployment --replicas=3

# Better: edit the YAML and re-apply (keeps file as source of truth)
# Change replicas: 3 → replicas: 5, then:
kubectl apply -f manifests/04-deployment-nginx.yaml
```

Always prefer editing the YAML and re-applying — that way your file matches reality.

---

## Rolling updates (zero downtime)

When you change the image version and re-apply, Kubernetes does a **rolling update**:

```
Before:  Pod(1.25)  Pod(1.25)  Pod(1.25)
                    ↓
Step 1:  Pod(1.25)  Pod(1.25)  Pod(1.27)   ← new one up
Step 2:  Pod(1.25)  Pod(1.27)  Pod(1.27)   ← old one down
Step 3:  Pod(1.27)  Pod(1.27)  Pod(1.27)   ← done
```

It never takes all Pods down at once — traffic keeps flowing.

```bash
# Update the image in your YAML, then:
kubectl apply -f manifests/04-deployment-nginx.yaml

# Watch it happen live
kubectl rollout status deployment/nginx-deployment

# If something goes wrong — rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# See rollout history
kubectl rollout history deployment/nginx-deployment
```

---

## Connecting the Service to the Deployment

Our existing `nginx-service` (from 03-services.md) already works with the Deployment.
The Service uses `selector: app: nginx` — and our Deployment's Pods all have `app: nginx`.

So the Service now load-balances across **all 3 Pods** automatically.

```
External IP
    │
    ▼
nginx-service (LoadBalancer)
    │  selector: app=nginx
    ├──▶ Pod-1 (app=nginx)
    ├──▶ Pod-2 (app=nginx)
    └──▶ Pod-3 (app=nginx)
```

No changes needed to the Service YAML — labels do the wiring.

---

## Cleanup

```bash
# Delete the Deployment (also deletes its ReplicaSet and Pods)
kubectl delete deployment nginx-deployment

# Or via file
kubectl delete -f manifests/04-deployment-nginx.yaml
```
