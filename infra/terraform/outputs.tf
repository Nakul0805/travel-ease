# outputs.tf - Expose useful values after deployment 
 
output "ecs_cluster_name" { 
  description = "Name of the ECS cluster" 
  value       = aws_ecs_cluster.travelease.name 
} 
 
output "application_load_balancer_dns" { 
  description = "DNS name of the ALB (your app URL)" 
  value       = aws_lb.app.dns_name 
} 
 
output "application_url" { 
  description = "Full URL to access your frontend" 
  value       = "http://${aws_lb.app.dns_name}"
} 
