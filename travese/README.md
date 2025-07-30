# TravelEase: Cloud-Native Microservices Deployment

## Overview
TravelEase is a travel-tech platform with independent microservices for booking, payment, and user management. This monorepo provides a fully automated, cloud-native deployment pipeline using Docker, AWS ECS, Terraform, Jenkins, Prometheus, Grafana, and CloudWatch.

## Structure
- `services/` — Microservices (Booking, Payment, User)
- `infra/terraform/` — Infrastructure as Code (AWS ECS, ECR, networking)
- `infra/jenkins/` — Jenkins CI/CD pipeline
- `infra/monitoring/` — Prometheus & Grafana configs
- `infra/logging/` — CloudWatch agent config

## Quick Start
1. Build and push Docker images using Jenkins.
2. Deploy infrastructure with Terraform.
3. Monitor with Prometheus & Grafana.
4. View logs and alerts in CloudWatch.

## Tech Stack
- Docker, AWS ECS, Terraform, Jenkins, Prometheus, Grafana, CloudWatch
