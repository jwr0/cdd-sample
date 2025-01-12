data "aws_iam_policy_document" "ecs_execution_role_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_execution_role_policy" {
  statement {
    sid       = "ECRGetAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRGetImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [
      aws_ecr_repository.web_to_pdf.arn,
      aws_ecr_repository.svg_to_pdf.arn,
    ]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.ecs.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_execution_role" {
  name   = "${var.environment_name}-ecs-execution-role"
  policy = data.aws_iam_policy_document.ecs_execution_role_policy.json
  tags = {
    Name = "${var.environment_name}-ecs-execution-role"
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.environment_name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_trust_policy.json
  tags = {
    Name = "${var.environment_name}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_role.arn
}

resource "aws_ecs_cluster" "default" {
  name = var.environment_name
}

resource "aws_ecs_service" "web_to_pdf" {
  name    = "${var.environment_name}-web-to-pdf"
  cluster = aws_ecs_cluster.default.id
  task_definition = "${aws_ecs_task_definition.web_to_pdf.family}:${max(
    aws_ecs_task_definition.web_to_pdf.revision,
    data.aws_ecs_task_definition.web_to_pdf.revision
  )}" # If Codepipeline has deployed a higher revision, use that instead of the one which was initially deployed by Terraform
  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.web_to_pdf_containers.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_to_pdf_external.arn
    container_name   = "web-to-pdf"
    container_port   = 443
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_to_pdf_internal.arn
    container_name   = "web-to-pdf"
    container_port   = 443
  }
}

data "aws_ecs_task_definition" "web_to_pdf" {
  depends_on      = [aws_ecs_task_definition.web_to_pdf]
  task_definition = aws_ecs_task_definition.web_to_pdf.family
}

resource "aws_ecs_task_definition" "web_to_pdf" {
  family                   = "${var.environment_name}-web-to-pdf"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions = jsonencode([{
    name      = "web-to-pdf"
    image     = "${aws_ecr_repository.web_to_pdf.repository_url}:latest"
    essential = true
    user      = "root" # You might not do this in production, but I want port 443 for this code sample.
    environment = [
      {
        name  = "HTTPS_PORT"
        value = "443"
      }
    ]
    portMappings = [{
      protocol      = "tcp"
      containerPort = 443
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "web-to-pdf"
      }
    }
  }])
}

resource "aws_ecs_service" "svg_to_pdf" {
  name    = "${var.environment_name}-svg-to-pdf"
  cluster = aws_ecs_cluster.default.id
  task_definition = "${aws_ecs_task_definition.svg_to_pdf.family}:${max(
    aws_ecs_task_definition.svg_to_pdf.revision,
    data.aws_ecs_task_definition.svg_to_pdf.revision
  )}" # If Codepipeline has deployed a higher revision, use that instead of the one which was initially deployed by Terraform
  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.svg_to_pdf_containers.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.svg_to_pdf_external.arn
    container_name   = "svg-to-pdf"
    container_port   = 443
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.svg_to_pdf_internal.arn
    container_name   = "svg-to-pdf"
    container_port   = 443
  }
}

data "aws_ecs_task_definition" "svg_to_pdf" {
  depends_on      = [aws_ecs_task_definition.svg_to_pdf]
  task_definition = aws_ecs_task_definition.svg_to_pdf.family
}

resource "aws_ecs_task_definition" "svg_to_pdf" {
  family                   = "${var.environment_name}-svg-to-pdf"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions = jsonencode([{
    name      = "svg-to-pdf"
    image     = "${aws_ecr_repository.svg_to_pdf.repository_url}:latest"
    essential = true
    user      = "root" # You might not do this in production, but I want port 443 for this code sample.
    environment = [
      {
        name  = "HTTPS_PORT"
        value = "443"
      }
    ]
    portMappings = [{
      protocol      = "tcp"
      containerPort = 443
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "svg-to-pdf"
      }
    }
  }])
}