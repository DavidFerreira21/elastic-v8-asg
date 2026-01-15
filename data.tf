locals {
  name_prefix            = coalesce(var.name_prefix, "es-single")
  es_9200_cidr_effective = length(var.es_9200_cidr_blocks) > 0 ? var.es_9200_cidr_blocks : [var.vpc_cidr]
}

# Lookup subnet to place EBS in the same AZ as the instance.
#data "aws_subnet" "selected" {
#  id = var.subnet_id
#}

