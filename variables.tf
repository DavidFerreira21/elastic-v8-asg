variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Name prefix for resources."
  type        = string
  default     = "asapflow"
}

variable "vpc_id" {
  description = "VPC ID where the instance will run."
  type        = string
  default     = "vpc-016047663e0ef25e7"
}

# variable "vpc_cidr" {
#   description = "VPC CIDR allowed to access port 9200 if no specific CIDRs are provided."
#   type        = string
#   default     = "10.125.0.0/16"
# }

variable "subnet_id" {
  description = "Subnet ID for the instance."
  type        = string
  default     = "subnet-0a25520585372912b"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "Optional SSH key name. Leave empty to use SSM only."
  type        = string
  default     = "david-key"
}

variable "associate_public_ip" {
  description = "Attach a public IP to the instance."
  type        = bool
  default     = false
}

variable "image_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-085faab2e35bc0c11"
}

variable "es_cidr_blocks" {
  description = "CIDR blocks allowed to access port 9200. Defaults to VPC CIDR when empty."
  type        = list(string)
  default     = ["10.125.0.0/16"]
}



variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH (optional)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "es_data_volume_size" {
  description = "Size of the Elasticsearch data volume in GiB."
  type        = number
  default     = 50
}

variable "es_data_volume_iops" {
  description = "IOPS for gp3 data volume."
  type        = number
  default     = 3000
}

variable "es_data_volume_throughput" {
  description = "Throughput (MiB/s) for gp3 data volume."
  type        = number
  default     = 125
}

variable "data_device_name" {
  description = "Device name used when attaching the EBS volume."
  type        = string
  default     = "/dev/sdf"
}

variable "tags" {
  description = "Common tags for all resources."
  type        = map(string)
  default     = { "Environment" = "hml" }
}


variable "elastic_password_secret_arn" {
  description = "arn do secret para credencias do elastic"
  type        = string
  default     = "arn:aws:secretsmanager:us-east-1:652613197255:secret:asapflow/elastic-VCZzw4"

}

variable "elastic_password_secret_key" {
  description = "Key do Json aonde esta as credencias do elastic no secret"
  type        = string
  default     = "ELASTIC_PWD"

}