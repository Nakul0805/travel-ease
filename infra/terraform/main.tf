provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "booking" {
  name = "travelease-booking"
}
resource "aws_ecr_repository" "payment" {
  name = "travelease-payment"
}
resource "aws_ecr_repository" "user" {
  name = "travelease-user"
}

# ECS Cluster
resource "aws_ecs_cluster" "travelease" {
  name = "travelease-cluster"
}

# Add ECS services, task definitions, ALB, and service discovery here
