variable "api_key" {
  description = "API key for Flask services"
  type        = string
  default     = "your-secret-key"
}
# variables.tf - Input variables for Terraform 
# These are passed from Jenkins during deployment 
 
variable "aws_region" { 
  description = "AWS region to deploy resources" 
  type        = string 
  default     = "ap-south-1" 
} 
 
variable "booking_image_uri" { 
  description = "ECR URI for the Booking service Docker image" 
  type        = string 
} 
 
variable "payment_image_uri" { 
  description = "ECR URI for the Payment service Docker image" 
  type        = string 
} 
 
variable "user_image_uri" { 
  description = "ECR URI for the User service Docker image" 
  type        = string 
} 
 
variable "frontend_image_uri" { 
  description = "ECR URI for the Frontend (React) Docker image" 
  type        = string 
} 
