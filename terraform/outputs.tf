output "application_public_ip" {
  description = "Public IP address of the application instance."
  value       = module.application.public_ip
}

output "frontend_url" {
  description = "Streamlit frontend URL."
  value       = "http://${module.application.public_ip}:8501"
}

output "rds_endpoint" {
  description = "Private RDS endpoint; reachable only from the VPC."
  value       = module.database.db_address
}

output "vpc_id" {
  value = module.networking.vpc_id
}
