module "ecs_with_codebuild" {
  source           = "../../modules/aws/ecs_with_codebuild"
  environment_name = "cdd"
}

output "web_to_pdf_hostname" {
  value = module.ecs_with_codebuild.web_to_pdf_hostname
}