# GUVI Project-02: CI/CD Deployment Using Docker, Jenkins and AWS

## 1. Project Overview

This project implements an automated CI/CD pipeline to deploy a React-based Kanban Task Manager application using Docker, Jenkins, Docker Hub and AWS EC2.

Whenever a developer pushes code to GitHub, a webhook triggers Jenkins. Jenkins checks the code, builds the application, creates a Docker image, pushes it to Docker Hub and deploys it to AWS EC2.

The deployment uses a Blue-Green strategy to reduce application downtime.

## 2. Technology Stack

* Application: React, TypeScript and Vite
* Source Control: Git and GitHub
* CI/CD: Jenkins
* Containerization: Docker
* Container Registry: Docker Hub
* Cloud Platform: AWS EC2
* Operating System: Ubuntu Server
* Reverse Proxy: Nginx
* Deployment Strategy: Blue-Green

## 3. Architecture and Workflow

GitHub → GitHub Webhook → Jenkins → Lint and Build → Docker Image → Docker Hub → AWS EC2 → Blue-Green Deployment → Health Check

### Workflow explanation

1. Developer pushes application changes to GitHub.
2. GitHub webhook automatically triggers the Jenkins pipeline.
3. Jenkins checks out the latest source code.
4. Jenkins installs dependencies and runs lint checks.
5. Jenkins builds the React application.
6. Docker creates a multi-stage image using a lightweight Alpine build environment and an unprivileged Nginx runtime.
7. Jenkins authenticates with Docker Hub using stored Jenkins credentials.
8. Jenkins pushes versioned and latest Docker image tags.
9. Jenkins executes the Blue-Green deployment script on EC2.
10. The script deploys the new image to the inactive container slot.
11. Docker health checks verify that the new container is healthy.
12. Nginx switches traffic to the newly deployed slot.
13. Jenkins performs an application health check and reports the pipeline result.

## 4. Docker Implementation

The Dockerfile uses a multi-stage build:

* Build stage: Node.js Alpine image.
* Runtime stage: Nginx unprivileged Alpine image.
* Only the compiled application files are copied into the runtime image.
* The container runs as a non-root user.
* Docker HEALTHCHECK verifies application availability.

Container resource limits:

* Memory: 512 MB
* CPU: 0.5

## 5. AWS Infrastructure

The application runs on an Ubuntu EC2 instance in AWS Mumbai Region (ap-south-1).

Instance configuration:

* Instance type: t3.medium
* Operating system: Ubuntu
* Docker Engine installed
* Jenkins installed
* Nginx installed as a reverse proxy

Security group:

* Port 80: Application HTTP access
* Port 8080: Restricted Jenkins access and GitHub webhook access
* Port 22: Restricted SSH access

Blue-Green containers are bound to localhost ports and are not directly exposed to the internet.

## 6. Blue-Green Deployment

Two application containers are maintained:

| Slot  | Container    | Internal Port |
| ----- | ------------ | ------------- |
| Blue  | kanban-blue  | 8081          |
| Green | kanban-green | 8082          |

Nginx listens on port 80 and forwards traffic to the active container.

The deployment script:

* Identifies the currently active slot.
* Selects the inactive slot.
* Pulls the requested Docker image tag.
* Starts the new container with resource limits.
* Waits for its Docker health check.
* Updates the Nginx upstream.
* Tests and reloads Nginx.
* Checks application health.
* Restores the previous Nginx upstream if the post-switch health check fails.

The previous container remains running as a rollback option.

Deployment script location on EC2:

`/usr/local/bin/deploy-kanban-bluegreen`

Version-controlled repository location:

`scripts/deploy-kanban-bluegreen.sh`

## 7. Jenkins Pipeline Stages

The Jenkinsfile contains these stages:

1. Checkout
2. Lint
3. Build and Test
4. Docker Build
5. Push to Docker Hub
6. Blue-Green Deploy
7. Health Check

Docker Hub credentials are stored in Jenkins Credentials rather than hardcoded in the repository.

## 8. Deployment Verification

The deployment was verified on AWS EC2.

Commands used:

```bash
sudo cat /etc/kanban-active-slot

sudo grep -n proxy_pass \
  /etc/nginx/sites-available/kanban-blue-test

curl -I http://127.0.0.1/

curl -fsS http://127.0.0.1/health

sudo docker ps
```

Successful deployment results:

* Active slot: Blue
* Nginx upstream: 127.0.0.1:8081
* Application HTTP response: 200 OK
* Application health: healthy
* Blue container: Image tag 4, healthy
* Green container: Image tag 3, healthy
* Jenkins Build #4: SUCCESS

## 9. Application Access

Application URL:

http://52.66.248.241/

GitHub repository:

https://github.com/subhan0807/kanban-dashboard

Docker Hub repository:

https://hub.docker.com/r/subhan0807/kanban-dashboard

## 10. Project Outcome

Successfully implemented an automated CI/CD pipeline integrating GitHub, Jenkins, Docker Hub and AWS EC2.

The project demonstrates automated source checkout, code validation, Docker image creation, registry publishing, container deployment, health monitoring and Blue-Green traffic switching.

The deployment workflow reduces manual deployment effort and keeps the previous application version available for rollback.

## 11. Future Improvements

* Configure HTTPS using a domain and TLS certificate.
* Secure Jenkins with HTTPS and authenticated webhook validation.
* Add automated Docker image vulnerability scanning.
* Improve deployment rollback and failure testing.
* Add centralized application logging and monitoring.
