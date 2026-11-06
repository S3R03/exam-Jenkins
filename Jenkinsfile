pipeline {
    environment {
        DOCKER_ID = "s3r0"
        DOCKER_IMAGE_MOVIE = "movie"
        DOCKER_IMAGE_CAST = "cast"
        DOCKER_TAG = "v.${BUILD_ID}.0"
    }
    agent any
    stages {
        stage('Docker Build') {
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
 
        stage('Docker run') {
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
 
                        sleep 10
 
                        docker run -d -p 8001:8000 --name movie_service \
                            -e DATABASE_URI=postgresql://movie_db_username:movie_db_password@movie_db/movie_db_dev \
                            -e CAST_SERVICE_HOST_URL=http://cast_service:8000/api/v1/casts/ \
                            --network run-net \
                            $DOCKER_ID/$DOCKER_IMAGE_MOVIE:$DOCKER_TAG
 
                        docker run -d -p 8002:8000 --name cast_service \
                            -e DATABASE_URI=postgresql://cast_db_username:cast_db_password@cast_db/cast_db_dev \
                            --network run-net \
                            $DOCKER_ID/$DOCKER_IMAGE_CAST:$DOCKER_TAG
 
                        sleep 10
                    '''
                }
            }
        }
 
        stage('Test Acceptance') {
            steps {
                script {
                    sh '''
                        curl -f localhost:8001/api/v1/movies/openapi.json
                        curl -f localhost:8002/api/v1/casts/openapi.json
                    '''
                }
            }
        }
 
        stage('Docker Push') {
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS")
            }
            steps {
                script {
                    sh '''
                        docker login -u $DOCKER_ID -p $DOCKER_PASS
                        docker push $DOCKER_ID/$DOCKER_IMAGE_MOVIE:$DOCKER_TAG
                        docker push $DOCKER_ID/$DOCKER_IMAGE_CAST:$DOCKER_TAG
                    '''
                }
            }
        }
 
        stage('Deployment in exam-dev') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                script {
                    sh '''
                        kubectl apply -f k8s/databases.yaml -n exam-dev
 
                        helm upgrade --install cast charts -n exam-dev \
                            --set fullnameOverride=cast \
                            --set image.repository=$DOCKER_ID/$DOCKER_IMAGE_CAST \
                            --set image.tag=$DOCKER_TAG \
                            --set env.DATABASE_URI=postgresql://cast_db_username:cast_db_password@cast-db/cast_db_dev
 
                        helm upgrade --install movie charts -n exam-dev \
                            --set fullnameOverride=movie \
                            --set image.repository=$DOCKER_ID/$DOCKER_IMAGE_MOVIE \
                            --set image.tag=$DOCKER_TAG \
                            --set env.DATABASE_URI=postgresql://movie_db_username:movie_db_password@movie-db/movie_db_dev \
                            --set env.CAST_SERVICE_HOST_URL=http://cast/api/v1/casts/
                    '''
                }
            }
        }
 
        stage('Deployment in exam-qa') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                script {
                    sh '''
                        kubectl apply -f k8s/databases.yaml -n exam-qa
 
                        helm upgrade --install cast charts -n exam-qa \
                            --set fullnameOverride=cast \
                            --set image.repository=$DOCKER_ID/$DOCKER_IMAGE_CAST \
                            --set image.tag=$DOCKER_TAG \
                            --set env.DATABASE_URI=postgresql://cast_db_username:cast_db_password@cast-db/cast_db_dev
 
                        helm upgrade --install movie charts -n exam-qa \
                            --set fullnameOverride=movie \
                            --set image.repository=$DOCKER_ID/$DOCKER_IMAGE_MOVIE \
                            --set image.tag=$DOCKER_TAG \
                            --set env.DATABASE_URI=postgresql://movie_db_username:movie_db_password@movie-db/movie_db_dev \
                            --set env.CAST_SERVICE_HOST_URL=http://cast/api/v1/casts/
                    '''
                }
            }
        }
 
        stage('Deployment in exam-staging') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                script {
                    sh '''
                        kubectl apply -f k8s/databases.yaml -n exam-staging
 
                        helm upgrade --install cast charts -n exam-staging \
                            --set fullnameOverride=cast \
                            --set image.repository=$DOCKER_ID/$DOCKER_IMAGE_CAST \
                            --set image.tag=$DOCKER_TAG \
                            --set env.DATABASE_URI=postgresql://cast_db_username:cast_db_password@cast-db/cast_db_dev
 
                        helm upgrade --install movie charts -n exam-staging \
                            --set fullnameOverride=movie \
                            --set image.repository=$DOCKER_ID/$DOCKER_IMAGE_MOVIE \
                            --set image.tag=$DOCKER_TAG \
                            --set env.DATABASE_URI=postgresql://movie_db_username:movie_db_password@movie-db/movie_db_dev \
                            --set env.CAST_SERVICE_HOST_URL=http://cast/api/v1/casts/
                    '''
                }
            }
        }
 
        stage('Deployment in exam-prod') {
            when {
                branch 'master'
            }
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                timeout(time: 15, unit: "MINUTES") {
                    input message: 'Deploy to production?', ok: 'Yes'
                }
                script {
                    sh '''
                        kubectl apply -f k8s/databases.yaml -n exam-prod
 
                        helm upgrade --install cast charts -n exam-prod \
                            --set fullnameOverride=cast \
                            --set image.repository=$DOCKER_ID/$DOCKER_IMAGE_CAST \
                            --set image.tag=$DOCKER_TAG \
                            --set env.DATABASE_URI=postgresql://cast_db_username:cast_db_password@cast-db/cast_db_dev
 
                        helm upgrade --install movie charts -n exam-prod \
                            --set fullnameOverride=movie \
                            --set image.repository=$DOCKER_ID/$DOCKER_IMAGE_MOVIE \
                            --set image.tag=$DOCKER_TAG \
                            --set env.DATABASE_URI=postgresql://movie_db_username:movie_db_password@movie-db/movie_db_dev \
                            --set env.CAST_SERVICE_HOST_URL=http://cast/api/v1/casts/
                    '''
                }
            }
        }
    }
}