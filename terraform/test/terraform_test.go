package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformCodeServer(t *testing.T) {
	t.Parallel()

	// Pick a random AWS region to test in
	awsRegion := "us-west-2"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"aws_region": awsRegion,
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	instanceId := terraform.Output(t, terraformOptions, "vscode_server_instance_id")
	publicIp := terraform.Output(t, terraformOptions, "vscode_server_public_ip")
	cloudfrontUrl := terraform.Output(t, terraformOptions, "vscode_server_cloudfront_domain_name")
	ssmParameter := terraform.Output(t, terraformOptions, "vscode_server_password_ssm")

	// Verify the outputs are not empty
	assert.NotEmpty(t, instanceId)
	assert.NotEmpty(t, publicIp)
	assert.NotEmpty(t, cloudfrontUrl)
	assert.Equal(t, "/code-server/password", ssmParameter)

	// Verify the EC2 instance is running
	aws.GetInstancesByTag(t, awsRegion, "Name", "VSCodeServer")

	// Wait for the instance to be ready (UserData script to complete)
	time.Sleep(5 * time.Minute)

	// Verify SSM parameter exists
	parameterValue := aws.GetParameter(t, awsRegion, "/code-server/password")
	assert.NotEmpty(t, parameterValue)
}
