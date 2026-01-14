output "asg_name" {
  description = "Name of the Elasticsearch Auto Scaling Group."
  value       = aws_autoscaling_group.es.name
}

output "data_volume_id" {
  description = "ID of the persistent Elasticsearch data volume."
  value       = aws_ebs_volume.es_data.id
}

output "security_group_id" {
  description = "Security group ID for the Elasticsearch instance."
  value       = aws_security_group.es.id
}
