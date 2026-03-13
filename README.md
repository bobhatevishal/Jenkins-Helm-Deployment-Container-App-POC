# Project Snaplink: Helm-deployment-app (POC)

![Azure Kubernetes Service](https://img.shields.io/badge/Azure-Kubernetes%20Service%20(AKS)-blue?logo=microsoftazure)
![Helm](https://img.shields.io/badge/Helm-Package%20Manager-blue?logo=helm)
![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD%20Automation-blue?logo=jenkins)
![Terraform](https://img.shields.io/badge/Terraform-IaC%20Automation-blue?logo=terraform)

## 1. Executive Summary  ,,,,

This repository, **Helm-deployment-app** (codenamed **Snaplink**), is a multi-tier, containerized microservices application Proof of Concept (POC). It is designed for high availability and scalable deployment on **Azure Kubernetes Service (AKS)**. The project demonstrates a fully automated, state-of-the-art DevOps workflow:

* **Infrastructure as Code (IaC):** Using **Terraform** for reproducible and isolated Azure resource provisioning.
* **CI/CD Automation:** Using **Jenkins** for continuous integration, containerization, and continuous deployment of application components via **Helm charts**.

## 2. Architecture Overview

## architecture_diagram
<img width="784" height="704" alt="architecture_diagram" src="https://github.com/user-attachments/assets/8efb01e0-4913-474a-8c3c-1e20b3b2e7b0" />


### Application Architecture
Snaplink follows a standard, resilient microservices architecture comprising four core components:

| Component | Description | Layer |
| :--- | :--- | :--- |
| **Frontend** | User-facing web application. | Presentation |
| **API (Backend)** | Core business logic layer. | Application Logic |
| **Database (DB)** | Persistent data storage layer. | Data Persistence |
| **Cache (Redis)** | In-memory data store for caching. | Performance/Caching |

### Infrastructure Architecture (Azure)
The underlying infrastructure is fully provisioned using Terraform and deployed across four distinct, isolated environments: **Development (DEV)**, **Quality Assurance (QA)**, **User Acceptance Testing (UAT)**, and **Production (PROD)**.

Each environment consists of the following dedicated Azure resources, ensuring logical isolation and security:

* **Resource Group:** A logical container for the environment's resources.
* **Virtual Network (VNet):** A dedicated network space for secure microservice communication.
* **Azure Kubernetes Service (AKS):** The managed Kubernetes cluster where application pods are orchestrated.
* **Azure Container Registry (ACR):** A private Docker registry used to store and manage the container images.

## 3. Deployment Strategy (Kubernetes & Helm)

The application components are deployed to AKS using **Helm**, the package manager for Kubernetes. This approach ensures standardized, repeatable, and easily configurable deployments across all four environments.

### Umbrella Helm Chart
All microservices (frontend, api, db, redis) are packaged together under a single **Helm Chart** located in the `kube/snaplink` directory.

### Environment Configuration (`values.yaml`)
The deployment is highly parameterized. Environment-specific configurations, such as:
* Image registries (ACR URLs)
* Image tags (`IMAGE_TAG`)
* Database credentials
* Replica counts

...are controlled via the `values.yaml` file, simplifying cross-environment management.

## 4. CI/CD Pipeline Automation (Jenkins)

The CI/CD workflow is heavily **decoupled**, providing independent lifecycle management for both the core infrastructure and each individual application microservice.

### Infrastructure Pipeline
* **Location:** `cicd/infra-pipeline/Jenkinsfile`
* **Responsibility:** Manages the execution of Terraform scripts (plan, apply, destroy). Responsible for creating, updating, or destroying the base Azure resources (Resource Groups, VNets, AKS, ACR) for the selected environment subscription.

### Application Pipelines
Each microservice has its own dedicated pipeline for independent lifecycle management:

1.  **Frontend Pipeline:** `cicd/frontend-pipeline/Jenkinsfile`
2.  **API Pipeline:** `cicd/api-pipeline/Jenkinsfile`
3.  **Cache Pipeline:** `cicd/cache-pipeline/Jenkinsfile`
4.  **DB Pipeline:** `cicd/db-pipeline/Jenkinsfile`

#### Pipeline Workflow Definition:

| Phase | Description | Environment |
| :--- | :--- | :--- |
| **Build** | Authenticates with ACR, builds the Docker image from `src/`, and tags it using `{component_name}-{git_commit_hash}`. | **DEV Only** |
| **Push** | Pushes the newly built and tagged image to the DEV ACR. | **DEV Only** |
| **Deploy to DEV** | Updates the Umbrella Helm release on the DEV AKS cluster using the newly built image tag. | **DEV Only** |
| **Promote & Deploy** | Triggers the pipeline for higher environments (QA, UAT, PROD). It takes an existing, validated `IMAGE_TAG` built in DEV. The pipeline **pulls** that specific image from the previous environment's ACR, re-**tags** it, **pushes** it to the target environment's ACR, and finally **deploys** it to the corresponding AKS cluster via Helm. | **QA, UAT, PROD** |

## 5. Security and Credentials

* **Azure Authentication:** Jenkins uses secured **Azure Service Principals** (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`) stored in Jenkins credentials to authenticate and manage Azure resources via Terraform and the Azure CLI.
* **Subscription Isolation:** To enforce strict logical isolation, prevent accidental cross-environment deployments, and simplify cost management, **each environment (dev, qa, uat, prod) utilizes a dedicated and distinct Azure Subscription ID.**
* **Secret Management:** Database passwords and other sensitive configuration secrets are injected into the Helm deployments securely via the CI/CD pipeline, ensuring that no hardcoded secrets reside in the source code repository.
<img width="940" height="513" alt="image" src="https://github.com/user-attachments/assets/88bf3770-3e9a-43aa-a947-4a6c0a8a860d" />




