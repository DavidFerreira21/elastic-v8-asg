variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default = "us-east-1"
}

variable "name_prefix" {
  description = "Name prefix for resources."
  type        = string
  default     = "asapflow"
}

variable "vpc_id" {
  description = "VPC ID where the instance will run."
  type        = string
  default     = "vpc-0c0a172abb07f5b16"
}

variable "vpc_cidr" {
  description = "VPC CIDR allowed to access port 9200 if no specific CIDRs are provided."
  type        = string
  default = "0.0.0.0/0"
}

variable "subnet_id" {
  description = "Subnet ID for the instance."
  type        = string
  default = "subnet-0934443170b329e8e"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "Optional SSH key name. Leave empty to use SSM only."
  type        = string
  default     = ""
}

variable "associate_public_ip" {
  description = "Attach a public IP to the instance."
  type        = bool
  default     = false
}

variable "cis_ami_id" {
  description = "Optional explicit AMI ID for CIS Amazon Linux 2 Level 1."
  type        = string
  default     = ""
}

variable "es_9200_cidr_blocks" {
  description = "CIDR blocks allowed to access port 9200. Defaults to VPC CIDR when empty."
  type        = list(string)
  default     = []
}

variable "es_9200_source_security_group_ids" {
  description = "Security group IDs allowed to access port 9200."
  type        = list(string)
  default     = []
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH (optional)."
  type        = list(string)
  default     = []
}

variable "es_data_volume_size" {
  description = "Size of the Elasticsearch data volume in GiB."
  type        = number
  default     = 100
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
  default     = {"Environment" = "hml"}
}
