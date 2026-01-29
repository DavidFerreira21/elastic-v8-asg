locals {
  name_prefix            = coalesce(var.name_prefix, "es-single")
  
}

# Lookup subnet to place EBS in the same AZ as the instance.
#data "aws_subnet" "selected" {
#  id = var.subnet_id
#}

