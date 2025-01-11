resource "aws_cloudwatch_log_group" "codebuild" {
    name = "${var.environment_name}-codebuild"
    retention_in_days = 30
}