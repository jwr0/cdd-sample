module "ecs_with_codebuild" {
  source           = "../../modules/aws/ecs_with_codebuild"
  environment_name = "cdd"
  on_prem_ip_address = "198.54.135.52/32"
  launch_production_ec2_instance = true
}

output "web_to_pdf_hostname" {
  value = "https://${module.ecs_with_codebuild.web_to_pdf_hostname}"
}

output "svg_to_pdf_hostname" {
  value = "https://${module.ecs_with_codebuild.svg_to_pdf_hostname}"
}