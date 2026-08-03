# 01 — Cluster Setup

## What is AKS?

Azure Kubernetes Service (AKS) is a **managed Kubernetes cluster** on Azure.
"Managed" means Azure handles the control plane (the brain of Kubernetes) for free.
You only pay for the worker nodes (VMs that run your workloads).

```
┌─────────────────────────────────────────────────┐
│                   AKS Cluster                   │
│                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    │
│  │  Control Plane  │    │   Worker Node   │    │
│  │  (managed by    │───▶│  (your VM,      │    │
│  │   Azure, free)  │    │   you pay here) │    │
│  └─────────────────┘    └─────────────────┘    │
└─────────────────────────────────────────────────┘
```

**Control Plane** contains:
- `kube-apiserver` — the front door, all kubectl commands go here
- `etcd` — the database that stores all cluster state
- `kube-scheduler` — decides which node runs each Pod
- `kube-controller-manager` — ensures desired state matches actual state

---

## What Terraform does — and the Azure CLI equivalent

### 1. Create a Resource Group

**Terraform (`main.tf`):**
```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-k8s-learning"
  location = "eastus"
}
```

**Azure CLI equivalent:**
```bash
az group create \
  --name rg-k8s-learning \
  --location eastus
```

A Resource Group is just a folder in Azure. Every resource (VMs, clusters, IPs) must live inside one.

---

### 2. Create the AKS Cluster

**Terraform (`main.tf`):**
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-learning"
  location            = "eastus"
  resource_group_name = "rg-k8s-learning"
  dns_prefix          = "aks-learning"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }
}
```

**Azure CLI equivalent:**
```bash
az aks create \
  --resource-group rg-k8s-learning \
  --name aks-learning \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys
```

**Key flags explained:**
| Flag | What it does |
|------|-------------|
| `--node-count 1` | 1 worker VM (cheap, enough to learn) |
| `Standard_B2s` | 2 vCPU, 4GB RAM burstable VM (~$30/mo) |
| `SystemAssigned` identity | AKS manages its own Azure permissions automatically |

---

### 3. Connect kubectl to the cluster

After cluster is created, you need to download credentials so `kubectl` can talk to it.

**Azure CLI:**
```bash
az aks get-credentials \
  --resource-group rg-k8s-learning \
  --name aks-learning
```

This writes a **kubeconfig** file to `~/.kube/config`.
kubectl reads this file to know: which cluster to talk to, and how to authenticate.

**Verify connection:**
```bash
kubectl get nodes        # lists your worker nodes
kubectl cluster-info     # shows control plane address
```

---

## Terraform workflow explained

```
terraform init     → downloads Azure provider plugin (like npm install)
terraform plan     → shows what WILL be created, nothing actually happens
terraform apply    → creates the resources on Azure
terraform destroy  → deletes everything (use when done learning to save money!)
```

The `.terraform/` folder and `terraform.tfstate` file are created locally.
`tfstate` is the source of truth — it maps your .tf files to real Azure resources.
Never delete `tfstate` manually.
