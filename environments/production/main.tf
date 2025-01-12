module "ecs_with_codebuild" {
  source                         = "../../modules/aws/ecs_with_codebuild"
  environment_name               = "cdd"
  on_prem_ip_address             = "1.2.3.4/32" # Replace with your on-prem (laptop) IP addres
  acm_certificate_arn            = "..."        # Replace with your ACM certificate ARN
  launch_production_ec2_instance = false        # Set to true to launch EC2 instance to simulate connectivity from within AWS.
}

output "web_to_pdf_hostname" {
  value = "https://${module.ecs_with_codebuild.web_to_pdf_hostname}"
}

output "svg_to_pdf_hostname" {
  value = "https://${module.ecs_with_codebuild.svg_to_pdf_hostname}"
}