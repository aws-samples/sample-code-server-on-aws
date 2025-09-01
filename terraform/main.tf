# Security Group for VSCode Server
resource "aws_security_group" "vscode_server_security_group" {
  name_prefix = "vscode-server-sg-"
  description = "Allow ingress from CloudFront prefix list"
  vpc_id      = local.vpc_id

  tags = merge(var.common_tags, {
    Name = "VSCodeServer-SecurityGroup"
  })
}

# Security Group Ingress Rule
resource "aws_security_group_rule" "vscode_server_security_group_ingress" {
  type              = "ingress"
  description       = "Open port 8080 for the CloudFront prefix list"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  security_group_id = aws_security_group.vscode_server_security_group.id
}

# Security Group Egress Rule
resource "aws_security_group_rule" "vscode_server_security_group_egress" {
  type              = "egress"
  description       = "Egress for vscode security group"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.internet_cidr_block]
  security_group_id = aws_security_group.vscode_server_security_group.id
}

# IAM Role for VSCode Server
resource "aws_iam_role" "vscode_server_iam_role" {
  name_prefix = "VSCodeServer-Role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  inline_policy {
    name = "SSMParameterAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ssm:PutParameter",
            "ssm:GetParameter"
          ]
          Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/code-server/*"
        }
      ]
    })
  }

  tags = var.common_tags
}

# Instance Profile
resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "VSCodeServer-InstanceProfile-"
  role        = aws_iam_role.vscode_server_iam_role.name

  tags = var.common_tags
}

# Elastic IP
resource "aws_eip" "vscode_server_eip" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "VSCodeServer-EIP"
  })
}

# User Data Script
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    version = var.vscode_server_version
    region  = data.aws_region.current.name
  }))
}

# EC2 Instance
resource "aws_instance" "vscode_server" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  subnet_id               = local.subnet_id
  vpc_security_group_ids  = [aws_security_group.vscode_server_security_group.id]
  iam_instance_profile    = aws_iam_instance_profile.instance_profile.name
  user_data_base64        = local.user_data
  monitoring              = true

  tags = merge(var.common_tags, {
    Name = "VSCodeServer"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Associate Elastic IP
resource "aws_eip_association" "vscode_server_eip_association" {
  instance_id   = aws_instance.vscode_server.id
  allocation_id = aws_eip.vscode_server_eip.id
}

# CloudFront Cache Policy
resource "aws_cloudfront_cache_policy" "vscode_server_cloudfront_cache_policy" {
  name        = "VSCodeServer-${random_id.cache_policy_suffix.hex}"
  comment     = "Cache policy for VSCode Server"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip = false

    cookies_config {
      cookie_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = [
          "Accept-Charset",
          "Authorization", 
          "Origin",
          "Accept",
          "Referer",
          "Host",
          "Accept-Language",
          "Accept-Encoding",
          "Accept-Datetime"
        ]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

# Random ID for cache policy name uniqueness
resource "random_id" "cache_policy_suffix" {
  byte_length = 4
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "vscode_server_cloudfront" {
  origin {
    domain_name = aws_eip.vscode_server_eip.public_dns
    origin_id   = "VS-code-server"

    custom_origin_config {
      http_port              = 8080
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled = true

  default_cache_behavior {
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "VS-code-server"
    compress                   = false
    viewer_protocol_policy     = "allow-all"
    cache_policy_id            = aws_cloudfront_cache_policy.vscode_server_cloudfront_cache_policy.id
    origin_request_policy_id   = var.origin_request_policy_id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.common_tags

  depends_on = [aws_eip_association.vscode_server_eip_association]
}
