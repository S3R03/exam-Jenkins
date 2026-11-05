pipeline {
environment { // Declaration of environment variables
DOCKER_ID = "s3r0" // replace this with your docker-id
DOCKER_IMAGE_MOVIE = "movie"
DOCKER_IMAGE_CAST = "cast"
DOCKER_TAG = "v.${BUILD_ID}.0" // we will tag our images with the current build in order to increment the value by 1 with each new build
}
agent any // Jenkins will be able to select all available agents
stages {
  stage(' Docker Build'){ // docker build image stage
    steps {
      script {
      sh '''
        docker rm -fv cast_db movie_db cast_service movie_service  
        docker network rm run-net || true
        docker build -t $DOCKER_ID/$DOCKER_IMAGE_MOVIE:$DOCKER_TAG movie-service/
        docker build -t $DOCKER_ID/$DOCKER_IMAGE_CAST:$DOCKER_TAG cast-service/
        sleep 6
      '''
      }
    }
  }
  stage('Docker run'){ // run container from our builded image
    steps {
      script {
      sh '''
        docker network create run-net
        
        docker run -d --name movie_db \
        -e POSTGRES_USER=movie_db_username \
        -e POSTGRES_PASSWORD=movie_db_password \
        -e POSTGRES_DB=movie_db_dev \
        --network run-net \
        postgres:12.1-alpine   
        
        docker run -d --name cast_db \
        -e POSTGRES_USER=cast_db_username \
        -e POSTGRES_PASSWORD=cast_db_password \
        -e POSTGRES_DB=cast_db_dev \
        --network run-net \
        postgres:12.1-alpine
        
        docker run -d -p 8001:8000 --name movie_service \
        -e DATABASE_URI=postgresql://movie_db_username:movie_db_password@movie_db/movie_db_dev \
        -e CAST_SERVICE_HOST_URL=http://cast_service:8000/api/v1/casts/ \
        --network run-net \
        $DOCKER_ID/$DOCKER_IMAGE_MOVIE:$DOCKER_TAG
        
        docker run -d -p 8002:8000 --name cast_service \
        --network run-net \
        -e DATABASE_URI=postgresql://cast_db_username:cast_db_password@cast_db/cast_db_dev \
        $DOCKER_ID/$DOCKER_IMAGE_CAST:$DOCKER_TAG

        sleep 10
      '''
      }
    }
  }
  stage('Test Acceptance'){ // we launch the curl command to validate that the container responds to the request
    steps {
      script {
      sh '''
        curl localhost:8001
        curl localhost:8002
      '''
      }
    }
  }
  stage('Docker Push'){ //we pass the built image to our docker hub account
    environment
    {
      DOCKER_PASS = credentials("DOCKER_HUB_PASS") // we retrieve  docker password from secret text called docker_hub_pass saved on jenkins
    }
    steps {
      script {
        sh '''
          docker login -u $DOCKER_ID -p $DOCKER_PASS
          docker push $DOCKER_ID/$DOCKER_IMAGE_MOIVE:$DOCKER_TAG
          docker push $DOCKER_ID/$DOCKER_IMAGE_CAST:$DOCKER_TAG
        '''
      }
    }
  }
  stage('Deployment in exam-dev'){
    environment {
    KUBECONFIG = credentials("config") // we retrieve  kubeconfig from secret file called config saved on jenkins
    }
    steps {
      script {
      sh '''
      rm -Rf ~/.kube
      mkdir ~/.kube
      ls
      cat $KUBECONFIG > ~/.kube/config
      cp charts/values.yaml values.yml
      cat values.yml
      sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
      helm upgrade --install app fastapi --values=values.yml --namespace exam-dev --create-namespace
      '''
      }
    }
  }
  stage('Deployment in exam-staging'){
    environment {
    KUBECONFIG = credentials("config") // we retrieve  kubeconfig from secret file called config saved on jenkins
    }
    steps {
      script {
      sh '''
      rm -Rf ~/.kube
      mkdir ~/.kube
      ls
      cat $KUBECONFIG > ~/.kube/config
      cp fastapi/values.yaml values.yml
      cat values.yml
      sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
      helm upgrade --install app fastapi --values=values.yml --namespace jenkins-lab-staging --create-namespace
      '''
      }
    }
  }
  stage('Deployment in exam-prod'){
    environment {
      KUBECONFIG = credentials("config") // we retrieve  kubeconfig from secret file called config saved on jenkins
      }
      steps {
        // Create an Approval Button with a timeout of 15minutes.
        // this require a manuel validation in order to deploy on production environment
        timeout(time: 15, unit: "MINUTES") {
          input message: 'Do you want to deploy in production ?', ok: 'Yes'
        }
        script {
          sh '''
          rm -Rf ~/.kube
          mkdir ~/.kube
          ls
          cat $KUBECONFIG > ~/.kube/config
          cp fastapi/values.yaml values.yml
          cat values.yml
          sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
          helm upgrade --install app fastapi --values=values.yml --namespace jenkins-lab-prod --create-namespace
          '''
        }
      }
    }
  }
}