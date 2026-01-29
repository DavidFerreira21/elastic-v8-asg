resource "aws_ebs_volume" "es_data" {
  availability_zone = "us-east-1a"
  size              = var.es_data_volume_size
  type              = "gp3"
  iops              = var.es_data_volume_iops
  throughput        = var.es_data_volume_throughput


  tags = merge(var.tags, {
    Name = "${local.name_prefix}-data"
  })

  # Keep data volume even if instance is recreated.
  lifecycle {
    prevent_destroy = false
  }
}
