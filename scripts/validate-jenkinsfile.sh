#!/bin/bash

echo ">>> Validating Jenkinsfile..."

# 1. Syntax check
if ! grep -q "pipeline" Jenkinsfile; then
    echo "ERROR: Jenkinsfile missing pipeline block"
    exit 1
fi

# 2. Check required credentials
REQUIRED_CREDS=("dockerhub-creds" "github-creds" "kubeconfig")
for cred in "${REQUIRED_CREDS[@]}"; do
    if ! grep -q "$cred" Jenkinsfile; then
        echo "ERROR: Missing credential reference: $cred"
        exit 1
    fi
done

# 3. Check DockerHub repos
if ! grep -q "rxteot/movie-service" Jenkinsfile; then
    echo "ERROR: Missing movie-service repo reference"
    exit 1
fi

if ! grep -q "rxteot/cast-service" Jenkinsfile; then
    echo "ERROR: Missing cast-service repo reference"
    exit 1
fi

