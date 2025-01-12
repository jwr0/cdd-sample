data "aws_iam_policy_document" "codebuild" {
  statement {
    sid    = "CodebuildLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.codebuild.arn}:*"
    ]
  }

  statement {
    sid    = "PushAndPullFromECR"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [
      aws_ecr_repository.web_to_pdf.arn,
      aws_ecr_repository.svg_to_pdf.arn,
    ]
  }

  statement {
    sid    = "PushAndPullFromECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "CodepipelineArtifacts"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "codebuild" {
  name        = "${var.environment_name}-codebuild"
  description = "Used by Codebuild to push images to ECR."
  policy      = data.aws_iam_policy_document.codebuild.json
}

data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.environment_name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

data "aws_caller_identity" "codebuild" {}

resource "aws_codebuild_project" "web_to_pdf" {
  name          = "${var.environment_name}-web-to-pdf"
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  source {
    type = "NO_SOURCE"
    buildspec = yamlencode({
      # This mostly comes from https://docs.aws.amazon.com/codepipeline/latest/userguide/ecs-cd-pipeline.html#cd-buildspec
      version = 0.2
      phases = {
        pre_build = {
          on-failure : "ABORT"
          commands = [
            "echo Logging in to Amazon ECR...",
            "aws --version",
            "aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin ${data.aws_caller_identity.codebuild.account_id}.dkr.ecr.$${AWS_DEFAULT_REGION}.amazonaws.com",
            "REPOSITORY_URI=${aws_ecr_repository.web_to_pdf.repository_url}",
            "COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)",
            "IMAGE_TAG=$${COMMIT_HASH:=$(date +%s)}",
            "docker pull $REPOSITORY_URI:latest || true", # So we can re-use the old layers in the cache for faster builds.
            "cat Dockerfile",
          ]
        }
        build = {
          on-failure : "ABORT"
          commands = [
            "echo Build started on `date`",
            "echo Building the Docker image...",
            "docker build -t $REPOSITORY_URI:$${IMAGE_TAG} --cache-from $REPOSITORY_URI:latest .",
            "docker tag $REPOSITORY_URI:$${IMAGE_TAG} $REPOSITORY_URI:latest",
          ]
        }
        post_build = {
          on-failure : "ABORT"
          commands = [
            "echo Build completed on `date`",
            "echo Pushing the Docker images...",
            "docker push $REPOSITORY_URI:$IMAGE_TAG",
            "docker push $REPOSITORY_URI:latest",
            "echo Writing image definitions file...",
            "printf '[{\"name\":\"web-to-pdf\",\"imageUri\":\"%s\"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json",
            "cat imagedefinitions.json",
          ]
        }
      }
      artifacts = {
        files = [
          "imagedefinitions.json",
        ]
      }
    })
  }

  tags = {
    Name = "${var.environment_name}-web-to-pdf"
  }
}

resource "aws_codebuild_project" "svg_to_pdf" {
  name          = "${var.environment_name}-svg-to-pdf"
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  source {
    type = "NO_SOURCE"
    buildspec = yamlencode({
      # This mostly comes from https://docs.aws.amazon.com/codepipeline/latest/userguide/ecs-cd-pipeline.html#cd-buildspec
      version = 0.2
      phases = {
        pre_build = {
          on-failure : "ABORT"
          commands = [
            "echo Logging in to Amazon ECR...",
            "aws --version",
            "aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin ${data.aws_caller_identity.codebuild.account_id}.dkr.ecr.$${AWS_DEFAULT_REGION}.amazonaws.com",
            "REPOSITORY_URI=${aws_ecr_repository.svg_to_pdf.repository_url}",
            "COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)",
            "IMAGE_TAG=$${COMMIT_HASH:=$(date +%s)}",
            "docker pull $REPOSITORY_URI:latest || true", # So we can re-use the old layers in the cache for faster builds.
            "cat Dockerfile",
          ]
        }
        build = {
          on-failure : "ABORT"
          commands = [
            "echo Build started on `date`",
            "echo Building the Docker image...",
            "docker build -t $REPOSITORY_URI:$${IMAGE_TAG} --cache-from $REPOSITORY_URI:latest .",
            "docker tag $REPOSITORY_URI:$${IMAGE_TAG} $REPOSITORY_URI:latest"
          ]
        }
        post_build = {
          on-failure : "ABORT"
          commands = [
            "echo Build completed on `date`",
            "echo Pushing the Docker images...",
            "docker push $REPOSITORY_URI:$IMAGE_TAG",
            "docker push $REPOSITORY_URI:latest",
            "echo Writing image definitions file...",
            "printf '[{\"name\":\"svg-to-pdf\",\"imageUri\":\"%s\"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json",
            "cat imagedefinitions.json",
          ]
        }
      }
      artifacts = {
        files = [
          "imagedefinitions.json",
        ]
      }
    })
  }

  tags = {
    Name = "${var.environment_name}-svg-to-pdf"
  }
}