# 02 — Pods

## What is a Pod?

A **Pod** is the smallest deployable unit in Kubernetes.
It wraps one or more containers and gives them shared networking and storage.

```
┌──────────────────────────────────────┐
│               Pod                    │
│                                      │
│  ┌────────────────────────────────┐  │
│  │         Container              │  │
│  │  (nginx, apache, your app...)  │  │
│  └────────────────────────────────┘  │
│                                      │
│  Shared: IP address, volumes         │
└──────────────────────────────────────┘
```

In most real setups you don't create Pods directly — you use Deployments.
But starting with raw Pods helps you understand the fundamentals.

---

## What we built

### Pod 1 — nginx (`manifests/01-first-pod.yaml`)

```yaml
apiVersion: v1        # Which Kubernetes API version handles this resource
kind: Pod             # The type of resource we're creating
metadata:
  name: my-first-pod  # Unique name for this Pod inside the cluster
  labels:
    app: nginx        # Key-value tag — used later to find/select this Pod
spec:
  containers:
    - name: nginx             # Name of the container inside the Pod
      image: nginx:latest     # Docker image to run (pulled from Docker Hub)
      ports:
        - containerPort: 80   # Port the container listens on (HTTP)
```

**Key concepts:**
| Field | What it does |
|---|---|
| `apiVersion: v1` | Core K8s API — Pods, Services live here |
| `kind: Pod` | Tells K8s what type of object this is |
| `labels` | Tags on the Pod — Services use these to find and route to Pods |
| `image: nginx:latest` | Pulled from Docker Hub on creation |
| `containerPort: 80` | Informational — documents which port the app uses |

---

### Pod 2 — Apache (`manifests/02-second-pod.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-second-pod
  labels:
    app: apache
spec:
  containers:
    - name: apache
      image: httpd:latest   # Apache HTTP server image
      ports:
        - containerPort: 80
```

Same structure, different image (`httpd` = Apache). Both run on port 80 but they are separate Pods with different IPs inside the cluster.

---

## How to apply (kubectl)

```bash
# Apply a single manifest
kubectl apply -f manifests/01-first-pod.yaml
kubectl apply -f manifests/02-second-pod.yaml

# Check Pods are running
kubectl get pods

# Describe a Pod (see events, errors, IP)
kubectl describe pod my-first-pod

# See logs from the container
kubectl logs my-first-pod

# Open a shell inside the container
kubectl exec -it my-first-pod -- /bin/bash

# Delete a Pod
kubectl delete pod my-first-pod
```

---

## Pod lifecycle

```
Pending → ContainerCreating → Running → (Completed / Failed / CrashLoopBackOff)
```

| Status | Meaning |
|---|---|
| `Pending` | Scheduled but image not pulled yet |
| `Running` | Container started, health check passing |
| `CrashLoopBackOff` | Container keeps crashing — check `kubectl logs` |

---

## Important limitation of raw Pods

If a raw Pod dies, **Kubernetes does NOT restart it automatically**.
That's why real workloads use **Deployments** (next topic) — they manage Pods for you.
