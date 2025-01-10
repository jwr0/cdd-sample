module "ecs_with_codebuild" {
  source           = "../../modules/aws/ecs_with_codebuild"
  environment_name = "cdd"
}