output "rds_endpoint" {
  description = "rds_endpoint"
  value       = module.db.db_instance_endpoint
}

output "wordpress_image_id" {
  description = "created_ami_id"
  value       = data.aws_ami.wordpress_image.id
}