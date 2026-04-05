# Jenkins — Préparation avant le pipeline
> À faire **une seule fois** au début du projet

---

## 0. Prérequis — Outils installés sur la VM

Vérifier que tout est dispo dans le PATH :

```bash
which docker
which helm
which kubectl
```

Chaque commande doit retourner un chemin (ex: `/usr/bin/docker`).

---

## 1. Donner les droits Docker à Jenkins

Jenkins doit pouvoir lancer des commandes Docker :

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

> Sans ça, le stage Build échoue avec `permission denied`.

---

## 2. Créer les namespaces Kubernetes

```bash
kubectl create namespace dev
kubectl create namespace qa
kubectl create namespace staging
kubectl create namespace prod
```

---

## 3. Credentials à créer dans Jenkins

`Jenkins → Manage Jenkins → Credentials → Global → Add Credential`

| ID | Type | Contenu | Utilisé pour |
|---|---|---|---|
| `dockerhub` | Username/Password | Login Docker Hub | Push des images |
| `kubeconfig` | Secret file | `/etc/rancher/k3s/k3s.yaml` | Helm → K3s |
| `values-movie-secret` | Secret file | `values-movie-secret.yaml` | Password PostgreSQL movie |
| `values-cast-secret` | Secret file | `values-cast-secret.yaml` | Password PostgreSQL cast |

### Récupérer le kubeconfig

```bash
cat /etc/rancher/k3s/k3s.yaml
```
Copier le contenu → uploader comme Secret file dans Jenkins.

### Structure des fichiers secret

```yaml
# values-movie-secret.yaml
secret:
  POSTGRES_PASSWORD: tonmotdepasse
```

```yaml
# values-cast-secret.yaml
secret:
  POSTGRES_PASSWORD: tonmotdepasse
```

> Ces fichiers sont dans `.gitignore` — ne jamais les commiter sur GitHub.

---

## 4. Configurer le pipeline Jenkins

`Jenkins → New Item → Pipeline → nom : fastapi`

### Paramètres SCM

| Champ | Valeur |
|---|---|
| Definition | Pipeline script from SCM |
| SCM | Git |
| Repository URL | URL de ton repo GitHub |
| Branch | `*/dev` et `*/master` |
| Script Path | `Jenkinsfile` |

### Trigger

Activer **GitHub hook trigger for GITScm polling**

---

## 5. Configurer le webhook GitHub

`GitHub → repo → Settings → Webhooks → Add webhook`

| Champ | Valeur |
|---|---|
| Payload URL | `http://<IP-EC2>:8080/github-webhook/` |
| Content type | `application/json` |
| Events | `Just the push event` |

---

## Récapitulatif

```
✅ Docker, Helm, kubectl accessibles
✅ Jenkins dans le groupe docker
✅ 4 namespaces créés (dev, qa, staging, prod)
✅ 4 credentials créés dans Jenkins
✅ Pipeline configuré (SCM → GitHub)
✅ Webhook GitHub configuré
```

**Après ça → écrire le Jenkinsfile.**