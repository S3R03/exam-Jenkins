# fastapiapp Helm Chart

Generic Helm chart for FastAPI microservices with PostgreSQL.

## Usage

helm install <release-name> ./charts \
  -f ./values-<service>.yaml \
  -f ./values-secret.yaml \
  -n <namespace>

## Secret management

Secrets are never committed to Git.
See values-secret.yaml (gitignored) or pass via CLI:

  --set secret.POSTGRES_PASSWORD=yourpassword

In production: use AWS Secrets Manager or HashiCorp Vault.

preparation jenkins
docker credentials
k3s
cat /etc/rancher/k3s/k3s.yaml
test