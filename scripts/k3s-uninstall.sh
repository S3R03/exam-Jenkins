#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-server}"

echo ">>> Uninstalling k3s (${ROLE})"

if [[ "$ROLE" == "server" ]]; then
    if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
        echo "Running k3s server uninstall script..."
        /usr/local/bin/k3s-uninstall.sh
    else
        echo "k3s server uninstall script not found."
        exit 1
    fi
elif [[ "$ROLE" == "agent" ]]; then
    if [[ -f /usr/local/bin/k3s-agent-uninstall.sh ]]; then
        echo "Running k3s agent uninstall script..."
        /usr/local/bin/k3s-agent-uninstall.sh
    else
        echo "k3s agent uninstall script not found."
        exit 1
    fi
else
    echo "Unknown role: $ROLE"
    exit 1
fi

echo ">>> Cleaning residual directories"

rm -rf /etc/rancher/k3s \
       /var/lib/rancher/k3s \
       /var/lib/kubelet \
       /etc/systemd/system/k3s*.service \
       /etc/systemd/system/multi-user.target.wants/k3s*.service \
       /var/lib/cni \
       /var/log/containers \
       /var/log/pods \
       /run/k3s

echo ">>> k3s uninstall complete."

