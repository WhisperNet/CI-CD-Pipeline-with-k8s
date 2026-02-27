# CI/CD Pipeline with Kubernetes

A Spring Boot web application with a fully automated CI/CD pipeline that builds, tests, containerizes, and deploys to an Amazon EKS cluster using Jenkins.

---

## Overview

This project demonstrates a production-style CI/CD workflow for a Java Maven application. Jenkins orchestrates every phase of the pipeline — from running tests and bumping the Maven version, to publishing a Docker image and applying the updated Kubernetes manifest on EKS.

---

## Architecture

```
 Developer Push
      |
      v
 ┌─────────────┐
 │   Jenkins   │  (pipeline defined in Jenkinsfile)
 └──────┬──────┘
        │
        ├─── 1. mvn test
        │
        ├─── 2. Increment Maven version (pom.xml)
        │
        ├─── 3. mvn package  →  java-maven-app-<version>.jar
        │
        ├─── 4. docker build  →  whispernet/java-app-k8s-cicd:<version>
        │         docker push  →  Docker Hub
        │
        ├─── 5. envsubst java-depl.yaml
        │         kubectl apply   →  Amazon EKS
        │
        └─── 6. git commit & push  (updated pom.xml version)

                        Amazon EKS
                   ┌─────────────────────────────┐
                   │  Deployment (2 replicas)     │
                   │  ┌──────────┐ ┌──────────┐  │
                   │  │ java-app │ │ java-app │  │
                   │  │ :8080    │ │ :8080    │  │
                   │  └──────────┘ └──────────┘  │
                   │         LoadBalancer         │
                   │          Service :8080       │
                   └─────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Application | Java 8, Spring Boot 2.3 |
| Build | Apache Maven 3.9 |
| Unit Testing | JUnit 4 |
| Logging | Logstash Logback Encoder |
| Containerization | Docker (Amazon Corretto 8 / Alpine) |
| Container Registry | Docker Hub |
| CI/CD | Jenkins + Shared Library |
| Orchestration | Kubernetes (Amazon EKS) |
| Cloud | AWS (EKS, IAM credentials) |
| Local Dev | Docker Compose + PostgreSQL |

---

## Repository Structure

```
.
├── src/
│   ├── main/
│   │   ├── java/com/example/
│   │   │   └── Application.java        # Spring Boot entry point
│   │   └── resources/static/
│   │       └── index.html              # Static welcome page
│   └── test/
│       └── java/
│           └── AppTest.java            # JUnit test for Application
├── Dockerfile                          # Container image definition
├── docker-compose.yaml                 # Local run (app + PostgreSQL)
├── java-depl.yaml                      # Kubernetes Deployment & Service
├── Jenkinsfile                         # Active CI/CD pipeline
├── Old.Jenkinsfile.Archive             # Previous EC2-based pipeline (archived)
├── server-script.sh                    # Helper script for EC2 deployment (legacy)
└── pom.xml                             # Maven project descriptor
```

---

## CI/CD Pipeline Stages

The active pipeline is defined in [`Jenkinsfile`](Jenkinsfile) and uses reusable steps from the [jenkins-shared-library-master](https://github.com/WhisperNet/jenkins-shared-library-master).

| Stage | What Happens |
|---|---|
| **test** | Runs `mvn test` to execute all JUnit tests |
| **Increment version** | Bumps the patch version in `pom.xml` via `incrementVersionMvn()` |
| **build jar** | Packages the application with `mvn package` via `buildJar()` |
| **build and push docker image** | Builds the Docker image tagged with the new version and pushes to Docker Hub |
| **deploy to k8s** | Substitutes `${IMAGE_NAME}` in `java-depl.yaml` and runs `kubectl apply` against EKS using AWS credentials |
| **Commit incremented version** | Commits and pushes the updated `pom.xml` back to the repository |

---

## Kubernetes Manifest

`java-depl.yaml` defines two Kubernetes resources applied to EKS on every successful build:

- **Deployment** — runs 2 replicas of the application container, pulling the versioned image from Docker Hub using the `dockerhub-key` image pull secret.
- **Service** — a `LoadBalancer`-type service that exposes port 8080 publicly.

The `${IMAGE_NAME}` placeholder is resolved at deploy time using `envsubst`.

---

## Docker Image

```
Base image : amazoncorretto:8-alpine3.17-jre
Exposed port: 8080
Entrypoint  : java -jar java-maven-app-*.jar
```

The image is published to Docker Hub as `whispernet/java-app-k8s-cicd:<version>`.

---

## Local Development

Run the application alongside a PostgreSQL instance using Docker Compose:

```bash
export IMAGE=whispernet/java-app-k8s-cicd:<version>
docker compose -f docker-compose.yaml up -d
```

The application will be available at `http://localhost:8080`.

Alternatively, use the helper script:

```bash
bash server-script.sh whispernet/java-app-k8s-cicd:<version>
```

---

## Prerequisites

- Jenkins with Maven (`maven-3.9.11`) and `kubectl` configured
- Jenkins credentials:
  - `docker-hub` — Docker Hub username/password
  - `aws_access_key_id` / `aws_secret_accesss_key` — AWS IAM credentials with EKS access (note: the credential ID contains a deliberate triple-s; it must match the name used in the Jenkinsfile exactly)
  - `github-repo-access` — SSH key for pushing the version commit
- EKS cluster with `dockerhub-key` image pull secret pre-created
- `envsubst` available on the Jenkins agent

---

## Application Endpoints

| Path | Description |
|---|---|
| `GET /` | Serves the static `index.html` welcome page |
