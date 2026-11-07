# GUVI Project-02: Kanban Task Manager

An automated CI/CD deployment project demonstrating how to build, containerize and deploy a React application using **GitHub, Jenkins, Docker, Docker Hub and AWS EC2**.

## Live Application

**Application URL:** http://52.66.248.241/

## Technology Stack

* React, TypeScript and Vite
* Git and GitHub
* Jenkins CI/CD
* Docker and Docker Hub
* AWS EC2 (Ubuntu)
* Nginx Reverse Proxy
* Blue-Green Deployment

## CI/CD Workflow

GitHub → GitHub Webhook → Jenkins → Build and Test → Docker Build → Docker Hub → AWS EC2 → Blue-Green Deployment → Health Check

Every GitHub push automatically triggers the Jenkins pipeline.

## Key Features

* Automated CI/CD pipeline using Jenkins.
* Multi-stage Docker build with an unprivileged Nginx runtime.
* Versioned Docker images published to Docker Hub.
* Automated Blue-Green deployment.
* Docker health checks and application validation.
* Container resource limits.
* Previous deployment slot retained for rollback.

## Blue-Green Deployment

Two application containers are maintained:

| Slot  | Container    | Port |
| ----- | ------------ | ---- |
| Blue  | kanban-blue  | 8081 |
| Green | kanban-green | 8082 |

Nginx routes incoming application traffic to the active healthy container.

Deployment script: [deploy-kanban-bluegreen.sh](scripts/deploy-kanban-bluegreen.sh)

## Project Documentation

For complete implementation details, AWS architecture, Jenkins pipeline stages, Docker configuration, deployment workflow and verification commands, see:

[PROJECT-02-DEPLOYMENT.md](PROJECT-02-DEPLOYMENT.md)

## Project Links

* **GitHub:** https://github.com/subhan0807/kanban-dashboard
* **Docker Hub:** https://hub.docker.com/r/subhan0807/kanban-dashboard
* **Application:** http://52.66.248.241/

## Deployment Result

* Jenkins Build #4: SUCCESS
* Docker image deployed: `subhan0807/kanban-dashboard:4`
* Active slot: Blue
* Application response: HTTP 200 OK
* Application health: healthy
* Both Blue and Green containers running successfully.

## Project Outcome

Successfully implemented an automated end-to-end CI/CD pipeline from GitHub to AWS EC2 with Docker containerization and Blue-Green deployment.

GitHub push events automatically trigger the Jenkins pipeline.
Docker images are built, pushed to Docker Hub, and deployed on AWS EC2.
