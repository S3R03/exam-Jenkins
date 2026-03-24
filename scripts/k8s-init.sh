#!/usr/bin/env bash
set -euo pipefail

echo ">>> Creating minimal Kubernetes project structure"

# Base directories
mkdir -p k8s/namespaces
mkdir -p k8s/apps/my-app
mkdir -p k8s/environments/{dev,qa,staging,prod}

# Namespace files
cat <<EOF > k8s/namespaces/dev.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
EOF

cat <<EOF > k8s/namespaces/qa.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: qa
EOF

cat <<EOF > k8s/namespaces/staging.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
EOF

cat <<EOF > k8s/namespaces/prod.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
EOF

# App base manifests
cat <<EOF > k8s/apps/my-app/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:latest
EOF

cat <<EOF > k8s/apps/my-app/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
EOF

cat <<EOF > k8s/apps/my-app/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
spec:
  rules:
  - host: my-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80
EOF

# Environment kustomization files
for env in dev qa staging prod; do
cat <<EOF > k8s/environments/$env/kustomization.yaml
resources:
  - ../../namespaces/$env.yaml
  - ../../apps/my-app
EOF
done

echo ">>> Kubernetes project structure created"
echo ">>> Done"

