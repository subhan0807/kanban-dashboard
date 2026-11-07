pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'subhan0807/kanban-dashboard'
        CONTAINER_NAME = 'kanban-dashboard'
        APP_PORT = '80'
        CONTAINER_PORT = '8080'
    }

    stages {
        stage('Checkout') {
            steps {
                sh 'rm -f .deployment-started .previous-image'
                checkout scm
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    npm ci
                    npm run lint
                '''
            }
        }

        stage('Build and Test') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    env.IMAGE_TAG = "${BUILD_NUMBER}"
                    sh '''
                        docker build \
                          -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
                          -t ${DOCKER_IMAGE}:latest .
                    '''
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_TOKEN'
                )]) {
                    sh '''
                        set +x
                        echo "$DOCKER_TOKEN" | docker login \
                          -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    set -eu

                    PREVIOUS_IMAGE=$(docker inspect \
                      --format='{{.Config.Image}}' \
                      ${CONTAINER_NAME} 2>/dev/null || true)

                    echo "$PREVIOUS_IMAGE" > .previous-image
                    touch .deployment-started

                    docker pull ${DOCKER_IMAGE}:${IMAGE_TAG}

                    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      --restart unless-stopped \
                      --memory=512m \
                      --cpus=0.5 \
                      -p ${APP_PORT}:${CONTAINER_PORT} \
                      ${DOCKER_IMAGE}:${IMAGE_TAG}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    for i in $(seq 1 15); do
                        if curl -fsS http://127.0.0.1:${APP_PORT}/health \
                          >/dev/null; then
                            echo "Application health check passed"
                            exit 0
                        fi
                        sleep 2
                    done

                    echo "Health check failed"
                    docker logs ${CONTAINER_NAME}
                    exit 1
                '''
            }
        }
    }

    post {
        failure {
            sh '''
                if [ -f .deployment-started ]; then
                    echo "Deployment failed. Starting rollback..."

                    PREVIOUS_IMAGE=$(cat .previous-image 2>/dev/null || true)

                    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                    if [ -n "$PREVIOUS_IMAGE" ]; then
                        echo "Restoring previous image: $PREVIOUS_IMAGE"

                        docker run -d \
                          --name ${CONTAINER_NAME} \
                          --restart unless-stopped \
                          --memory=512m \
                          --cpus=0.5 \
                          -p ${APP_PORT}:${CONTAINER_PORT} \
                          "$PREVIOUS_IMAGE"

                        echo "Rollback container started"
                    else
                        echo "No previous image available for rollback"
                    fi
                fi
            '''
        }
    }
}
