# Code-Server Terraform Template

This Terraform template deploys a code-server instance on AWS EC2 with CloudFront distribution and automatic password storage in AWS Systems Manager Parameter Store.

## Architecture

The template creates:
- EC2 instance running Ubuntu 22.04 LTS with code-server
- Security Group allowing CloudFront access on port 8080
- CloudFront distribution for global access
- Elastic IP for static public IP
- IAM role with SSM permissions
- SSM Parameter Store for secure password storage

## Supported Regions

- `us-west-2` (default)
- `us-east-1`
- `ap-southeast-1`

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with appropriate permissions
- AWS credentials configured (via AWS CLI, environment variables, or IAM roles)

## Required AWS Permissions

Your AWS credentials need the following permissions:
- EC2: Create/manage instances, security groups, elastic IPs
- IAM: Create/manage roles and instance profiles
- CloudFront: Create/manage distributions and cache policies
- SSM: Create/read parameters
- VPC: Describe VPCs and subnets (if using default VPC)

## Quick Start

1. **Clone and navigate to the terraform directory:**
   ```bash
   git clone <repository-url>
   cd terraform/
   ```

2. **Copy and customize the example variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your preferred settings
   ```

3. **Initialize and apply Terraform:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Retrieve the code-server password:**
   ```bash
   # Get just the password value
   aws ssm get-parameter --name "/code-server/password" --with-decryption --region <your-region> --query 'Parameter.Value' --output text
   
   # Or get full parameter details
   aws ssm get-parameter --name "/code-server/password" --with-decryption --region <your-region>
   
   # Using the terraform output command
   $(terraform output -raw password_retrieval_command)
   ```

5. **Access code-server:**
   - Get the CloudFront URL from terraform output: `terraform output vscode_server_cloudfront_domain_name`
   - Open the URL in your browser
   - Enter the password retrieved from SSM

## Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region to deploy resources | `us-west-2` | No |
| `vscode_server_version` | Version of code-server to install | `4.91.1` | No |
| `instance_type` | EC2 instance type | `t2.xlarge` | No |
| `vpc_id` | VPC ID (uses default VPC if empty) | `""` | No |
| `subnet_id` | Subnet ID (uses default subnet if empty) | `""` | No |
| `internet_cidr_block` | CIDR block for internet access | `0.0.0.0/0` | No |
| `origin_request_policy_id` | CloudFront origin request policy ID | `216adef6-5c7f-47e4-b989-5492eafa07d3` | No |
| `common_tags` | Common tags for all resources | `{Project = "code-server"}` | No |

### Example terraform.tfvars

```hcl
aws_region            = "us-west-2"
vscode_server_version = "4.91.1"
instance_type         = "t2.xlarge"

# Optional: Use existing VPC/subnet
# vpc_id    = "vpc-12345678"
# subnet_id = "subnet-12345678"

common_tags = {
  Project     = "code-server"
  Environment = "dev"
  Owner       = "your-name"
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `vscode_server_cloudfront_domain_name` | CloudFront URL for accessing code-server |
| `vscode_server_public_ip` | Public IP address of the instance |
| `vscode_server_private_ip` | Private IP address of the instance |
| `vscode_server_instance_id` | EC2 instance ID |
| `vscode_server_role_arn` | IAM role ARN |
| `vscode_server_password_ssm` | SSM parameter path for password |
| `password_retrieval_command` | AWS CLI command to get password |

## Code-Server Configuration

The code-server is configured to:
- Listen on `0.0.0.0:8080` (accessible via CloudFront)
- Use password authentication (stored in SSM)
- Include the Amazon Q extension pre-installed
- Run as a systemd service under the `ubuntu` user

You can modify the configuration by connecting to the instance:
```bash
# Connect via SSM Session Manager
aws ssm start-session --target <instance-id> --region <region>

# Edit configuration
sudo nano /home/ubuntu/.config/code-server/config.yaml

# Restart service
sudo systemctl restart code-server@ubuntu
```

## Access Methods

### Option 1: CloudFront (Recommended)
Access via the CloudFront distribution URL (from terraform output). This provides:
- Global edge locations for better performance
- HTTPS termination
- DDoS protection

### Option 2: Direct IP Access
Access directly via the public IP on port 8080 (HTTP only).

### Option 3: SSM Port Forwarding
Forward the code-server port to your local machine:
```bash
aws ssm start-session \
  --target <instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"portNumber":["8080"],"localPortNumber":["8080"],"host":["<private-ip>"]}' \
  --region <region>
```

## Security Considerations

- The security group only allows access from CloudFront IP ranges
- Password is stored encrypted in SSM Parameter Store
- Instance uses IAM roles (no hardcoded credentials)
- All traffic to CloudFront is over HTTPS
- Consider restricting `internet_cidr_block` for additional security

## Troubleshooting

### Check instance status:
```bash
# Get instance ID from terraform output
terraform output vscode_server_instance_id

# Check instance status
aws ec2 describe-instances --instance-ids <instance-id> --region <region>
```

### Check UserData script execution:
```bash
# Connect to instance
aws ssm start-session --target <instance-id> --region <region>

# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log | grep "INFO:"

# Check code-server service
sudo systemctl status code-server@ubuntu
```

### Verify SSM parameter:
```bash
aws ssm get-parameter --name "/code-server/password" --region <region>
```

## Testing

Basic Terratest is included in the `test/` directory:

```bash
cd test/
go mod init terraform-test
go mod tidy
go test -v -timeout 30m
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Differences from CloudFormation Template

This Terraform template provides the same functionality as the CloudFormation version with these improvements:
- Dynamic AMI lookup (always uses latest Ubuntu 22.04 LTS)
- Dynamic CloudFront prefix list lookup (works in any supported region)
- Additional output with password retrieval command
- Terraform validation for region constraints
- Modular file structure for better maintainability

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review AWS CloudWatch logs for the EC2 instance
3. Verify your AWS permissions and region support
