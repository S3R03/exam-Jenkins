# Useful commands

## Helm
helm template movie-service ./helm/charts \
  -f ./helm/values-movie.yaml \
  -f ./helm/values-movie-secret.yaml

  helm template cast-service ./helm/charts \
  -f ./helm/values-cast.yaml \
  -f ./helm/values-cast-secret.yaml

## installation des charts

## 1 cast service

helm install cast-service ./helm/charts \
  -f ./values-cast.yaml \
  -f ./values-cast-secret.yaml \
  -n dev

helm install movie-service ./charts \
  -f ./values-movie.yaml \
  -f ./values-movie-secret.yaml

## Debug
kubectl exec -it movie-service-db-0 -n dev -- env | grep POSTGRES

## Utils
echo "bW92aWVfZGJfcGFzc3dvcmQ=" | base64 --decode

1. Get the application URL by running these commands:
  export NODE_PORT=$(kubectl get --namespace dev -o jsonpath="{.spec.ports[0].nodePort}" services cast-service-fastapiapp)
  export NODE_IP=$(kubectl get nodes --namespace dev -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT

  docker build -t reasg/jenkins_for_devops_movie_service:latest ./movie-service/

  docker build -t reasg/jenkins_for_devops_cast_service:latest ./cast-service/

  docker push reasg/jenkins_for_devops_movie_service:latest
  docker push reasg/jenkins_for_devops_cast_service:latest

  docker run --rm \
  -e DATABASE_URI=postgresql://cast_db_username:cast_db_password@localhost/cast_db_dev \
  reasg/jenkins_for_devops_cast_service:latest

  # Supprimer la release Helm complètement
helm uninstall cast-service -n dev

# Réinstaller proprement
helm install cast-service ./helm/charts \
  -f ./helm/values-cast.yaml \
  -f ./helm/values-cast-secret.yaml \
  -n dev

helm install movie-service ./helm/charts \
  -f ./helm/values-movie.yaml \
  -f ./helm/values-movie-secret.yaml \
  -n dev

  docker build --no-cache -t reasg/jenkins_for_devops_cast_service:latest ./cast-service/
  docker build --no-cache -t reasg/jenkins_for_devops_movie_service:latest ./movie-service

  sudo crictl rmi reasg/jenkins_for_devops_cast_service:latest
  sudo crictl rmi reasg/jenkins_for_devops_movie_service:latest

  git diff --name-only HEAD~1 HEAD


  #jenkins ches git repo
  checkout scm
  Jenkins executes commandes with
  sh

##tests 

kubectl delete pod <release>-fastapiapp-test-connection -n <namespace>
helm test <release> -n <namespace> --logs