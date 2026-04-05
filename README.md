# Jenkins for DevOps — Exam Project
> FastAPI microservices CI/CD pipeline with Jenkins, Kubernetes (K3s), Docker and Helm

---

## Stack

| Outil | Rôle |
|---|---|
| FastAPI | Microservices (movie-service, cast-service) |
| PostgreSQL | Base de données par service |
| Nginx | Reverse proxy (docker-compose uniquement) |
| Docker / Docker Hub | Build et registry des images |
| Helm | Packaging et déploiement Kubernetes |
| K3s | Cluster Kubernetes léger (AWS EC2) |
| Jenkins | Orchestration CI/CD |

---

## Structure du projet

```
Jenkins_for_devops/
├── Jenkinsfile                   # Pipeline CI/CD
├── README.md
├── docker-compose.yml            # Environnement local
├── nginx_config.conf             # Config Nginx (docker-compose)
├── movie-service/                # Microservice films
│   ├── Dockerfile
│   └── app/
├── cast-service/                 # Microservice casting
│   ├── Dockerfile
│   └── app/
├── helm/
│   ├── charts/                   # Chart Helm partagé (1 chart, 2 releases)
│   │   ├── Chart.yaml
│   │   ├── values.yaml           # Valeurs par défaut
│   │   └── templates/
│   ├── values-movie.yaml         # Override movie-service
│   ├── values-cast.yaml          # Override cast-service
│   ├── values-movie-secret.yaml  # Secrets movie (ne pas commiter)
│   ├── values-cast-secret.yaml   # Secrets cast (ne pas commiter)
│   └── values-staging-prod.yaml  # Override staging/prod (ClusterIP)
└── k8s/
    └── ingress.yaml              # Ingress standalone (géré par kubectl)
```

---

## Lancer en local (docker-compose)

```bash
docker-compose up -d
```

- Movie service docs : http://localhost:8080/api/v1/movies/docs
- Cast service docs  : http://localhost:8080/api/v1/casts/docs

---

## Architecture Kubernetes

### Vue d'ensemble

```
Internet
    ↓
Traefik (Ingress Controller — inclus dans K3s)
    ↓
k8s/ingress.yaml (règles de routing)
    ↓                    ↓
/api/v1/movies     /api/v1/casts
    ↓                    ↓
movie-service-svc  cast-service-svc
    ↓                    ↓
Pods movie         Pods cast
    ↓                    ↓
PostgreSQL DB      PostgreSQL DB
```

### Ingress

L'Ingress est **géré par kubectl**, pas par Helm.  
L'Ingress Helm est désactivé dans tous les values :

```yaml
ingress:
  enabled: false
```

Un seul Ingress `k8s/ingress.yaml` centralise le trafic (équivalent du Nginx en docker-compose) :

```
/api/v1/movies  →  movie-service-fastapiapp:80
/api/v1/casts   →  cast-service-fastapiapp:80
```

### Service type par environnement

| Namespace | Service type | Accès disponible |
|---|---|---|
| dev | NodePort | NodePort (30007/30008) **+** Ingress |
| qa | NodePort | NodePort (30007/30008) **+** Ingress |
| staging | ClusterIP | Ingress uniquement |
| prod | ClusterIP | Ingress uniquement |

En dev/qa le NodePort permet de tester chaque service individuellement sans passer par l'Ingress — utile pour le debug.

---

## Déploiement manuel

### Prérequis — créer les namespaces

```bash
kubectl create namespace dev
kubectl create namespace qa
kubectl create namespace staging
kubectl create namespace prod
```

### Prérequis — image pull secret (registry privé)

```bash
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<user> \
  --docker-password=<token> \
  -n <namespace>
```

### Dev / QA

```bash
# movie-service
helm install movie-service ./helm/charts \
  -f helm/values.yaml \
  -f helm/values-movie.yaml \
  -f helm/values-movie-secret.yaml \
  -n dev

# cast-service
helm install cast-service ./helm/charts \
  -f helm/values.yaml \
  -f helm/values-cast.yaml \
  -f helm/values-cast-secret.yaml \
  -n dev

# Ingress
kubectl apply -f k8s/ingress.yaml -n dev
```

### Staging / Prod

```bash
# movie-service
helm install movie-service ./helm/charts \                                                      
  -f helm/values-movie.yaml \
  -f helm/values-movie-secret.yaml \
  -f helm/values-staging-prod.yaml \
  -n staging

# cast-service
helm install cast-service ./helm/charts \
  -f helm/values.yaml \
  -f helm/values-cast.yaml \
  -f helm/values-cast-secret.yaml \
  -f helm/values-staging-prod.yaml \
  -n staging

# Ingress
kubectl apply -f k8s/ingress.yaml -n staging
```

---

## Secrets — ne jamais commiter

Les fichiers `values-*-secret.yaml` contiennent les mots de passe PostgreSQL.  
Ils sont dans `.gitignore`.

Structure attendue :

```yaml
# values-movie-secret.yaml
secret:
  POSTGRES_PASSWORD: yourpassword
```

```yaml
# values-cast-secret.yaml
secret:
  POSTGRES_PASSWORD: yourpassword
```

---

## Pipeline Jenkins

Le pipeline est déclenché automatiquement depuis GitHub.

| Branche | Déploiement automatique | Déploiement manuel |
|---|---|---|
| dev | dev, qa, staging | — |
| master | — | prod uniquement |

---

## Docker Hub

Images disponibles sur : https://hub.docker.com/repositories/reasg

| Image | Tag |
|---|---|
| reasg/jenkins_for_devops_movie_service | latest |
| reasg/jenkins_for_devops_cast_service | latest |

# important ! to keep jenkins updated un Vm IP
sudo vim /var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml