def helmTest(String release, String namespace) {
    sh "kubectl wait deployment/${release}-fastapiapp \
          --for=condition=Available \
          --timeout=120s \
          -n ${namespace}"
    retry(2) {
        sh "kubectl delete pod ${release}-fastapiapp-test-connection -n ${namespace} --ignore-not-found"
        sh "helm test ${release} --logs -n ${namespace} --timeout 60s"
    }
    sh "kubectl delete pod ${release}-fastapiapp-test-connection -n ${namespace} --ignore-not-found"
}

pipeline {
    agent any
    
    environment {
        MOVIE_RELEASE = 'movie-service'
        CAST_RELEASE = 'cast-service'
    }

    
    stages {
        stage('Checkout') { 
            steps {
                checkout scm
                script {
                    def changes = sh(
                        script: 'git diff --name-only HEAD~1 HEAD',
                        returnStdout: true
                    )
                    echo "******** CHANGED FILES *********"
                    echo changes
                    echo "******** GIT_BRANCH = ${env.GIT_BRANCH} ********"

                    env.BUILD_MOVIE = 'false'
                    env.BUILD_CAST = 'false'
                    env.DEPLOY_MOVIE = 'false'
                    env.DEPLOY_CAST  = 'false'
                    env.SET_DEPLOY_TAG_MOVIE = ""
                    env.SET_DEPLOY_TAG_CAST = ""
                    env.BUILD_TAG= "${env.GIT_COMMIT}"

                    if (changes.contains('movie-service/')) {
                        env.IMAGE_MOVIE_NAME= 'reasg/jenkins_for_devops_movie_service'
                        env.BUILD_MOVIE = 'true'
                        env.DEPLOY_MOVIE = 'true'
                        env.SET_DEPLOY_TAG_MOVIE = "--set image.tag=${env.BUILD_TAG}"
                        
                    }
                    if (changes.contains('cast-service/')) {
                        env.IMAGE_CAST_NAME= 'reasg/jenkins_for_devops_cast_service'
                        env.BUILD_CAST = 'true'
                        env.DEPLOY_CAST = 'true' 
                        env.SET_DEPLOY_TAG_CAST = "--set image.tag=${env.BUILD_TAG}"
                    }  
                    echo "Contains helm/: ${changes.contains('helm/')}"
                    if (changes.contains('helm/')) {
                        env.DEPLOY_MOVIE = 'true'
                        env.DEPLOY_CAST = 'true'

                        if( env.BUILD_MOVIE == 'false') {
                        env.STABLE_TAG_MOVIE = sh(script: 'cat tags/.movie-image-tag', returnStdout: true).trim()
                        env.SET_DEPLOY_TAG_MOVIE = "--set image.tag=${env.STABLE_TAG_MOVIE}"
                        }
                        if( env.BUILD_CAST == 'false') {
                        env.STABLE_TAG_CAST = sh(script: 'cat tags/.cast-image-tag', returnStdout: true).trim()
                        env.SET_DEPLOY_TAG_CAST = "--set image.tag=${env.STABLE_TAG_CAST}"
                        }
                    }
                    
                    echo "=== DEPLOY_MOVIE = ${env.DEPLOY_MOVIE} ==="
                    echo "=== DEPLOY_CAST = ${env.DEPLOY_CAST} ==="                     
                }
            }
        }
        stage('Build & push'){
            when {
                anyOf{
                    environment name: 'BUILD_MOVIE', value: 'true' 
                    environment name: 'BUILD_CAST', value: 'true' 
                }
            }
             steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]){
                    sh 'echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin'
                    echo 'Loging succesfully'
                    script{
                        if ( env.BUILD_MOVIE == 'true' ) {
                            sh "docker build -t ${env.IMAGE_MOVIE_NAME}:${env.BUILD_TAG} ./movie-service"
                            sh "docker push ${env.IMAGE_MOVIE_NAME}:${env.BUILD_TAG}"
                        }
                        if ( env.BUILD_CAST == 'true' ) {
                            sh "docker build -t ${env.IMAGE_CAST_NAME}:${env.BUILD_TAG} ./cast-service"
                            sh "docker push ${env.IMAGE_CAST_NAME}:${env.BUILD_TAG}"
                        }  
                    }
                  
                }         
            }
        }
        stage('Deploy dev'){
            environment {
                NAMESPACE = 'dev'
                MOVIE_NODEPORT = '30007'
                CAST_NODEPORT = '30008'
            }
            when {
                allOf{
                    expression { env.GIT_BRANCH == 'origin/dev' }
                    anyOf{
                        environment name: 'DEPLOY_MOVIE', value: 'true' 
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps{
                withCredentials([
                    file(credentialsId: 'values-movie-secret', variable: 'MOVIE_SECRET'),
                    file(credentialsId: 'values-cast-secret', variable: 'CAST_SECRET')
                    ]){
                        script{
                            if (env.DEPLOY_MOVIE == 'true'){
                                sh "helm upgrade --install ${MOVIE_RELEASE} ./helm/charts \
                                    -f ./helm/values-movie.yaml \
                                    -f ${MOVIE_SECRET} \
                                    --set service.nodePort=${MOVIE_NODEPORT} \
                                    ${env.SET_DEPLOY_TAG_MOVIE } \
                                    -n ${NAMESPACE}"                        
                            }
                            if (env.DEPLOY_CAST == 'true'){
                                sh "helm upgrade --install ${CAST_RELEASE} ./helm/charts \
                                  -f ./helm/values-cast.yaml \
                                  -f ${CAST_SECRET} \
                                  --set service.nodePort=${CAST_NODEPORT} \
                                  ${env.SET_DEPLOY_TAG_CAST}  \
                                  -n ${NAMESPACE}"                       
                            }                    
                        } 
                    }

            }
        }
        stage('Test dev') {
            environment {
                NAMESPACE = 'dev'
            }
            when {
                allOf{
                    expression { env.GIT_BRANCH == 'origin/dev' }
                    anyOf{
                        environment name: 'DEPLOY_MOVIE', value: 'true'
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps {
                script {
                    if (env.DEPLOY_MOVIE == 'true') helmTest(MOVIE_RELEASE, NAMESPACE)
                    if (env.DEPLOY_CAST == 'true') helmTest(CAST_RELEASE, NAMESPACE)
                }
            }
        }
        stage('Deploy qa'){
            environment {
                NAMESPACE = 'qa'
                MOVIE_NODEPORT = '30009'
                CAST_NODEPORT = '30010'
            }
            when {
                allOf{
                    expression { env.GIT_BRANCH == 'origin/dev' }
                    anyOf{
                        environment name: 'DEPLOY_MOVIE', value: 'true' 
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps{
                withCredentials([
                    file(credentialsId: 'values-movie-secret', variable: 'MOVIE_SECRET'),
                    file(credentialsId: 'values-cast-secret', variable: 'CAST_SECRET')
                    ]){
                        script{
                            if (env.DEPLOY_MOVIE == 'true'){
                                sh "helm upgrade --install ${MOVIE_RELEASE} ./helm/charts \
                                    -f ./helm/values-movie.yaml \
                                    -f ${MOVIE_SECRET} \
                                    --set service.nodePort=${MOVIE_NODEPORT} \
                                    ${env.SET_DEPLOY_TAG_MOVIE } \
                                    -n ${NAMESPACE}"                            
                            }
                            if (env.DEPLOY_CAST == 'true'){
                                sh "helm upgrade --install ${CAST_RELEASE} ./helm/charts \
                                    -f ./helm/values-cast.yaml \
                                    -f ${CAST_SECRET} \
                                    --set service.nodePort=${CAST_NODEPORT} \
                                     ${env.SET_DEPLOY_TAG_CAST}  \
                                    -n ${NAMESPACE}"                          
                            }                    
                        } 
                    }
            }            
        }
        stage('Test qa') {
            environment {
                NAMESPACE = 'qa'
            }
            when {
                allOf{
                    expression { env.GIT_BRANCH == 'origin/dev' }
                    anyOf{
                        environment name: 'DEPLOY_MOVIE', value: 'true'
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps {
                script {
                    if (env.DEPLOY_MOVIE == 'true') helmTest(MOVIE_RELEASE, NAMESPACE)
                    if (env.DEPLOY_CAST == 'true') helmTest(CAST_RELEASE, NAMESPACE)
                }
            }
        }
        stage('Deploy staging'){
            environment {
                NAMESPACE = 'staging'
            }
            when {
                allOf {
                    expression { env.GIT_BRANCH == 'origin/dev' }
                    anyOf {
                        environment name: 'DEPLOY_MOVIE', value: 'true'
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps{
                withCredentials([
                    file(credentialsId: 'values-movie-secret', variable: 'MOVIE_SECRET'),
                    file(credentialsId: 'values-cast-secret', variable: 'CAST_SECRET')
                    ]){
                        script{
                            if (env.DEPLOY_MOVIE == 'true'){
                                sh "helm upgrade --install ${MOVIE_RELEASE} ./helm/charts \
                                    -f ./helm/values-movie.yaml \
                                    -f ./helm/values-staging-prod.yaml \
                                    -f ${MOVIE_SECRET} \
                                    ${env.SET_DEPLOY_TAG_MOVIE } \
                                    -n ${NAMESPACE}"                            
                            }
                            if (env.DEPLOY_CAST == 'true'){
                                sh "helm upgrade --install ${CAST_RELEASE} ./helm/charts \
                                    -f ./helm/values-cast.yaml \
                                    -f ./helm/values-staging-prod.yaml \
                                    -f ${CAST_SECRET} \
                                     ${env.SET_DEPLOY_TAG_CAST}  \
                                    -n ${NAMESPACE}"                          
                            } 
                            sh "kubectl apply -f ./kubernetes/ingress.yaml -n ${NAMESPACE}"                   
                        } 
                    }
            }
        }
        stage('Test staging (helm test - intern )') {
            environment {
                NAMESPACE = 'staging'
            }
            when {
                allOf{
                    expression { env.GIT_BRANCH == 'origin/dev' }
                    anyOf{
                        environment name: 'DEPLOY_MOVIE', value: 'true'
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps {
                script {
                    if (env.DEPLOY_MOVIE == 'true') helmTest(MOVIE_RELEASE, NAMESPACE)
                    if (env.DEPLOY_CAST == 'true') helmTest(CAST_RELEASE, NAMESPACE)
                }
            }
        }
        stage('Test staging Ingress (curl extern)'){
            when {
                allOf{
                    expression { env.GIT_BRANCH == 'origin/dev' }
                    anyOf{
                        environment name: 'DEPLOY_MOVIE', value: 'true'
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps {
                script {
                    def publicIP = sh(script: 'curl -s http://checkip.amazonaws.com', returnStdout: true).trim()
                    retry(2) {
                        sh "sleep 15"
                        sh "curl -fL http://${publicIP}/api/v1/movies"
                        sh "curl -fL http://${publicIP}/api/v1/casts/docs"
                    }
                }
            }
        }
        stage('Saving Tags') {
            when {
                allOf{
                    expression { env.GIT_BRANCH == 'origin/dev' }
                    anyOf{
                        environment name: 'BUILD_MOVIE', value: 'true'
                        environment name: 'BUILD_CAST', value: 'true'
                    }
                }
            }
            steps{
                script {
                    if (env.BUILD_MOVIE == 'true') {
                        sh "echo ${env.BUILD_TAG} > ./tags/.movie-image-tag"
                    }
                    if (env.BUILD_CAST == 'true') {
                        sh "echo ${env.BUILD_TAG} > ./tags/.cast-image-tag"
                    }
                def branch = env.GIT_BRANCH.replace('origin/', '')
                withCredentials([usernamePassword(
                    credentialsId: 'GITHUB_CREDS',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]){
                                sh """
                        git config user.email "jenkins@ci"
                        git config user.name "Jenkins"
                        git add ./tags/
                        git commit -m "ci: update image tags [skip ci]"
                        git push https://\${GIT_USER}:\${GIT_TOKEN}@github.com/\${GIT_USER}/Jenkins_for_devops.git HEAD:${branch}
                     """
                    }
                }
            }
        }
        stage('Sanity Check'){
            when {
                expression { env.GIT_BRANCH == 'origin/master' }
            }
            steps {
                input "Does the staging environment look ok? Do you want to continue DEPLOYING to PROD?"
            }
        }
        stage('Deploy prod'){
            environment {
                NAMESPACE = 'prod'
            }
            when {
                allOf {
                    expression { env.GIT_BRANCH == 'origin/master' }
                    anyOf {
                        environment name: 'DEPLOY_MOVIE', value: 'true'
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps{
                withCredentials([
                    file(credentialsId: 'values-movie-secret', variable: 'MOVIE_SECRET'),
                    file(credentialsId: 'values-cast-secret', variable: 'CAST_SECRET')
                    ]){
                        script{
                            if (env.DEPLOY_MOVIE == 'true'){
                                sh "helm upgrade --install ${MOVIE_RELEASE} ./helm/charts \
                                    -f ./helm/values-movie.yaml \
                                    -f ./helm/values-staging-prod.yaml \
                                    -f ${MOVIE_SECRET} \
                                    ${env.SET_DEPLOY_TAG_MOVIE } \
                                    -n ${NAMESPACE}"                            
                            }
                            if (env.DEPLOY_CAST == 'true'){
                                sh "helm upgrade --install ${CAST_RELEASE} ./helm/charts \
                                -f ./helm/values-cast.yaml \
                                    -f ./helm/values-staging-prod.yaml \
                                    -f ${CAST_SECRET} \
                                     ${env.SET_DEPLOY_TAG_CAST}  \
                                    -n ${NAMESPACE}"                          
                            } 
                            sh "kubectl apply -f ./kubernetes/ingress.yaml -n ${NAMESPACE}"                   
                        } 
                    }
            }
        }
        stage('Test prod (helm test - intern )') {
            environment {
                NAMESPACE = 'prod'
            }
            when {
                allOf{
                    expression { env.GIT_BRANCH == 'origin/master' }
                    anyOf{
                        environment name: 'DEPLOY_MOVIE', value: 'true'
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps {
                script {
                    if (env.DEPLOY_MOVIE == 'true') helmTest(MOVIE_RELEASE, NAMESPACE)
                    if (env.DEPLOY_CAST == 'true') helmTest(CAST_RELEASE, NAMESPACE)
                }
            }
        }
        stage('Test prod Ingress (curl extern)'){
            when {
                allOf{
                    expression { env.GIT_BRANCH == 'origin/master' }
                    anyOf{
                        environment name: 'DEPLOY_MOVIE', value: 'true'
                        environment name: 'DEPLOY_CAST', value: 'true'
                    }
                }
            }
            steps {
                script {
                    def publicIP = sh(script: 'curl -s http://checkip.amazonaws.com', returnStdout: true).trim()
                    retry(2) {
                        sh "sleep 15"
                        sh "curl -fL http://${publicIP}/api/v1/movies"
                        sh "curl -fL http://${publicIP}/api/v1/casts/docs"
                    }
                }
            }
        }        
    }      
}
