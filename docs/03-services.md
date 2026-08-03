# 03 — Services

## What is a Service?

A **Service** gives a stable network endpoint to reach one or more Pods.

Pods are ephemeral — they get new IPs when they restart.
A Service solves this by acting as a stable "front door" that always routes to the right Pods using **label selectors**.

```
Internet
   │
   ▼
┌──────────────────────────┐
│     Service (port 80)    │
│  selector: app=nginx     │──────▶  Pod (app=nginx)
└──────────────────────────┘
```

---

## Service types

| Type | Reachable from | Use case |
|---|---|---|
| `ClusterIP` | Inside cluster only | Internal communication between services |
| `NodePort` | Node's IP + a port (30000-32767) | Simple external access (dev/testing) |
| `LoadBalancer` | Public internet via Azure LB | Production, exposes app externally |

---

## What we built

### nginx LoadBalancer Service (`manifests/03-service-loadbalancer.yaml`)

```yaml
apiVersion: v1
kind: Service           # Type of resource: a Service
metadata:
  name: nginx-service   # Name of this service
spec:
  type: LoadBalancer    # Creates a public Azure Load Balancer with external IP
  selector:
    app: nginx          # Routes traffic to ALL pods with label app=nginx
  ports:
    - protocol: TCP
      port: 80          # Port the outside world connects to
      targetPort: 80    # Port on the Pod to forward traffic to
```

**Key concepts:**
| Field | What it does |
|---|---|
| `type: LoadBalancer` | Tells AKS to provision a public Azure Load Balancer |
| `selector: app: nginx` | Only routes to Pods that have the label `app: nginx` |
| `port: 80` | The port clients connect to on the external IP |
| `targetPort: 80` | The port on the Pod the traffic is forwarded to |

When `type: LoadBalancer` is used in AKS, Azure automatically creates a public IP.
It takes ~1-2 minutes to provision. The IP shows up under `EXTERNAL-IP` in `kubectl get services`.

---

## How to apply (kubectl)

```bash
# Apply the service
kubectl apply -f manifests/03-service-loadbalancer.yaml

# List services — watch for EXTERNAL-IP to populate
kubectl get services
kubectl get svc                          # shorthand

# Watch until external IP is assigned (Ctrl+C to stop)
kubectl get svc nginx-service --watch

# Describe to see full details including endpoints
kubectl describe svc nginx-service

# Test the service once external IP is ready
curl http://<EXTERNAL-IP>

# Delete the service
kubectl delete svc nginx-service
```

---

## How the selector works

The Service doesn't care about Pod names — only **labels**.

```
Service selector:  app=nginx
                       │
         ┌─────────────┤
         ▼             ▼
   my-first-pod    (any future pod with app=nginx)
   (app: nginx)
```

This is why labels matter so much — they are the glue between Services and Pods.

---

## What happens without a Service?

A Pod has a **cluster-internal IP** (like `10.244.x.x`) but:
- That IP changes every time the Pod restarts
- It's not reachable from outside the cluster

A Service gives a **stable, named endpoint** that survives Pod restarts.
