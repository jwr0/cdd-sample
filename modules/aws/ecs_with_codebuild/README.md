# CDD Code Sample - ECS Service with Deployment Pipeline

This module serves as a code sample which can deploy an ECS service to AWS Fargate,
with a deployment pipeline which builds the necessary Docker images.

## Use case

The requirements which this module satisfies are:

- This builds two ECS services, one for a web-to-pdf service and one for an svg-to-pdf service. Both services run on AWS Fargate.
- This builds two Codepipeline pipelines which use Codebuild to build the images for the services and push the images to ECR. Codepipeline then deploys the new images to ECS as part of each build.
- Each service needs to be reachable from at least one application hosted on-prem and at least one application hosted in AWS.
    * In the real world, an on-prem connection would happen over a VPN or similar. For the purposes of this code sample, we simulate connectivity with on-prem by using the user's IP address of their laptop. They should be able to `curl` both services from their laptop after deploying this module.
    * In the real world, the applications in AWS which connect to these services would already exist in AWS. For the purposes of this code sample, we simulate this connectivity by deploying an EC2 server into AWS which can `curl` both services.

## Usage

1. Review the variables seen below in this readme. You'll need to fill out:
  * `on_prem_ip_address`: This represents the on-prem IP address, and for testing purposes you can use the public IP of your laptop (eg. the IP seen at https://whatismyip.com or similar).
  * `acm_certificate_arn`: This should be the ARN of an ACM certificate which is already issued and available for usage in your account. In the real world Terraform would build this on its own, but presumably you would rather avoid writing DNS records into your DNS zones just for this code sample. Note that an HTTPS hostname mismatch is to be expected, and all services should be accessed using `curl -k` to work around the mismatch.
  * `launch_production_ec2_instance`: should be set to `false` when initially applying this infrastructure. This will be used later when verifying connectivity to the ECS services from within AWS.
2. `terraform apply`
3. In my experience, Codepipeline will already start building images as soon as the `apply` completes. But if it doesn't start on its own, you'll need to kick off a pipeline execution using the `Release Change` button in the AWS console any given pipeline. The services should not be expected to work until the pipeline has run at least once and built the image.
4. You can test connectity "from on-prem" by using a curl command, issued from the same IP address as the `on_prem_ip_address` (eg. from your laptop). The hostnames to use will be part of the output from `terraform apply`.
  * `curl -k https://cdd-web-to-pdf-external-1234567890.us-east-1.elb.amazonaws.com` (for example)
5. To test connectivity from inside AWS, set `launch_production_ec2_instance` to `true` and `terraform apply`. The server will spin up and connect to each service using curl. The logs for this can be seen in the instance log (AWS Console -> EC2 -> Instances -> Select the instance -> Actions -> Monitor and Troubleshoot -> Get System Log). It takes about 5-10 minutes after instance launch for the logs to become visible.
6. `terraform destroy` to clean up.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | The ARN of the ACM certificate to use for the ALBs. | `string` | n/a | yes |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The CIDR block to use for the VPC. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | The name of the environment to create. | `string` | n/a | yes |
| <a name="input_launch_production_ec2_instance"></a> [launch\_production\_ec2\_instance](#input\_launch\_production\_ec2\_instance) | Whether or not to launch an EC2 instance in which similates other servers running in AWS which hit the ECS services built by this module. | `bool` | `false` | no |
| <a name="input_on_prem_ip_address"></a> [on\_prem\_ip\_address](#input\_on\_prem\_ip\_address) | The publicly routable IP address of the on-prem network (or of your local laptop). Must be a valid CIDR (eg. if its a single IP address, it should end in /32). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_svg_to_pdf_hostname"></a> [svg\_to\_pdf\_hostname](#output\_svg\_to\_pdf\_hostname) | n/a |
| <a name="output_web_to_pdf_hostname"></a> [web\_to\_pdf\_hostname](#output\_web\_to\_pdf\_hostname) | n/a |
