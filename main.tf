resource "aws_security_group" "es" {
  name_prefix = "${local.name_prefix}-sg-"
  vpc_id      = var.vpc_id

  description = "Elasticsearch 8 single-node access"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-sg"
  })
}


resource "aws_security_group_rule" "es_9200_cidr" {
  count             = length(local.es_9200_cidr_effective)
  type              = "ingress"
  from_port         = 9200
  to_port           = 9200
  protocol          = "tcp"
  cidr_blocks       = [local.es_9200_cidr_effective[count.index]]
  security_group_id = aws_security_group.es.id
  description       = "Elasticsearch HTTP"
}

resource "aws_security_group_rule" "es_9200_sg" {
  count                    = length(var.es_9200_source_security_group_ids)
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  source_security_group_id = var.es_9200_source_security_group_ids[count.index]
  security_group_id        = aws_security_group.es.id
  description              = "Elasticsearch HTTP from SG"
}


resource "aws_security_group_rule" "ssh" {
  count             = length(var.ssh_cidr_blocks)
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_cidr_blocks[count.index]]
  security_group_id = aws_security_group.es.id
  description       = "SSH access"
}

resource "aws_iam_role" "es" {
  name_prefix = "${local.name_prefix}-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "es_volume" {
  name_prefix = "${local.name_prefix}-volume-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "es_volume" {
  role       = aws_iam_role.es.name
  policy_arn = aws_iam_policy.es_volume.arn
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.es.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "es" {
  name_prefix = "${local.name_prefix}-profile-"
  role        = aws_iam_role.es.name
}

resource "aws_launch_template" "es" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = "ami-01428df236e9b0b49"
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.es.name
  }

  network_interfaces {
    subnet_id                   = var.subnet_id
    security_groups             = [aws_security_group.es.id]
    associate_public_ip_address = var.associate_public_ip
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    volume_id   = aws_ebs_volume.es_data.id
    device_name = var.data_device_name
    region = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${local.name_prefix}-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "es" {
  name_prefix         = "${local.name_prefix}-asg-"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [var.subnet_id]

  launch_template {
    id      = aws_launch_template.es.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
