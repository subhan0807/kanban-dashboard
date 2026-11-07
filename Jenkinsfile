
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'subhan0807/kanban-dashboard'
        APP_URL = 'http://127.0.0.1'
    }

    stages {
        stage('Checkout') {
            steps {
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
                        export DOCKER_CONFIG=$(mktemp -d)
                        trap 'docker logout >/dev/null 2>&1 || true; rm -rf "$DOCKER_CONFIG"' EXIT

                        echo "$DOCKER_TOKEN" | docker login \
                          -u "$DOCKER_USER" --password-stdin

                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Blue-Green Deploy') {
            steps {
                sh '''
                    sudo -n /usr/local/bin/deploy-kanban-bluegreen "$IMAGE_TAG"
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Checking application through Nginx..."

                    for i in $(seq 1 15); do
                        if curl -fsS ${APP_URL}/health; then
                            echo "Blue-Green deployment successful"
                            exit 0
                        fi
                        sleep 2
                    done

                    echo "Application health check failed"
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
            echo 'Blue-Green deployment is complete.'
        }

        failure {
            sh '''
                echo "Pipeline failed. Checking deployment containers..."
                docker ps -a
                docker logs kanban-blue 2>/dev/null || true
                docker logs kanban-green 2>/dev/null || true
            '''
        }
    }
}
