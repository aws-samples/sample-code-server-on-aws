---
title: Hosting Code Server on EC2 and CloudFront Distribution
author: haimtran
date: 08/08/2024
---

## Supported Region

By default, the provided template supports the following regions.

| Region         | CloudFront Prefix List ID |
| -------------- | ------------------------- |
| us-west-2      | pl-82a045eb               |
| us-east-1      | pl-3b927c52               |
| ap-southeast-1 | pl-31a34658               |

To deploy in other region, you have to update the CloudFront prefix list id map. Check [docs](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-aws-managed-prefix-lists.html) for more details how to find the CloudFront prefix list per region.

```yaml
Mappings:
  CloudFrontPrefixListIdMappings:
    us-west-2:
      PrefixListId: "pl-82a045eb"
    us-east-1:
      PrefixListId: "pl-3b927c52"
    ap-southeast-1:
      PrefixListId: "pl-31a34658"
    <YOUR_SELECTED_REGION>:
      PrefixListId: <CLOUDFRONT_PREFIX_LIST_ID_FOR_THE_SELECTED_REGION>
```

## Deploy

To deploy the stack, you can use CLI as the below command or use the AWS CloudFormation console.

```bash
aws cloudformation create-stack \
 --stack-name code-server-stack \
 --template-body file://code-server-stack.yaml \
 --capabilities CAPABILITY_NAMED_IAM
```

The code-server-stack.yaml stack will:

- Create an EC2 instance and install the [code server](https://github.com/coder/code-server) using UserData.
- Expose the code server via a CloudFront distribution.

## Code Server Configuration

You can change the following parameters by editing the code-server-stack.yaml.

- EC2 instance type to host the code server (default t2.medium)
- Amazon Machine Image (AMI) (default [latest amazon linux 2023 in us-west-2](https://docs.aws.amazon.com/linux/al2023/ug/ec2.html))
- Code server [release version](https://github.com/coder/code-server/releases) (default [4.9.11](https://github.com/coder/code-server/releases/download/v4.91.1/code-server-4.91.1-linux-amd64.tar.gz))
- Select an existing VPCID and SubnetID (otherwise default VPC is selected)

You can change configuration of the code server by editting config.yaml at the below path.

```bash
/home/ec2-user/.config/code-server/config.yaml
```

Here is a sample content of config.yaml with authentication disabled.

```yaml
bind-addr: 0.0.0.0:8080
auth: none
password: 8766aa4b66cf555763e9564d
cert: false
```

## Access Code Server

**Option 1.** The code server has been exposed via a CloudFront distribution. You can find the https endpoint in the CloudFormation console output.

**Password Retrieval:** The code-server password is automatically stored in AWS Systems Manager Parameter Store. Retrieve it using:
```bash
aws ssm get-parameter --name "/code-server/password" --with-decryption --region <your-region>
```

**Option 2.** Use AWS System Manager (SSM) and port forwarding to forward the code server to local host as the following command. In this case, there are prerequisites:

- Setup [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html)
- Setup AWS credentials for a profile in ~/.aws/credentials
- Replace INSTANCE_ID, PROFILE_NAME, REGION into the below command

```bash
aws ssm start-session \
--target <INSTANCE_ID> \
--document-name AWS-StartPortForwardingSessionToRemoteHost \
--parameters "{\"portNumber\":[\"8080\"],\"localPortNumber\":[\"8080\"],\"host\":[\"<CODE_SERVER_EC2_PRIVATE_IP>\"]}" \
--profile <PROFILE_NAME>\
--region <REGION>
```
