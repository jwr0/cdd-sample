resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "${var.environment_name}-codebuild"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${var.environment_name}-ecs"
  retention_in_days = 30
}