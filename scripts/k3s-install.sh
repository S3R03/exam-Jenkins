#!/usr/bin/env bash
set -euo pipefail

echo "===================================================="
echo ">>> SECTION 1: k3s Installation"
echo "===================================================="

if command -v k3s >/dev/null 2>&1; then
    echo "k3s already installed, skipping installation"
else
    echo "Installing k3s (server mode)"
    curl -sfL https://get.k3s.io | sudo sh -
fi

echo
echo ">>> Installed k3s version:"
k3s --version || echo "k3s not found"


echo
echo "===================================================="
echo ">>> SECTION 2: kubectl Configuration"
echo "===================================================="

if ! grep -q "KUBECONFIG=/etc/rancher/k3s/k3s.yaml" ~/.bashrc; then
    echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "kubectl configured to use k3s cluster"


echo
echo "===================================================="
echo ">>> SECTION 3: Helm Installation"
echo "===================================================="

if command -v helm >/dev/null 2>&1; then
    echo "Helm already installed, skipping installation"
else
    echo "Installing Helm"
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

echo
echo ">>> Installed Helm version:"
helm version || echo "Helm not found"


echo
echo "===================================================="
echo ">>> SECTION 4: Namespace Creation"
echo "===================================================="

for ns in dev qa staging prod; do
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo "Namespaces created or already existed:"
kubectl get namespaces


echo
echo "===================================================="
echo ">>> SECTION 5: Cluster Verification"
echo "===================================================="

kubectl get nodes -o wide  || true
kubectl get pods -A -o wide || true

echo
echo "===================================================="
echo ">>> INSTALLATION COMPLETE"
echo "===================================================="

