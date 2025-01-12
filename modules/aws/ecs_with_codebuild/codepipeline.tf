# Normally Codepipeline would be hooked up to GitHub or similar and would
# use webhooks to kick off each build. But in the context of this code
# sample, we dont want the hassle of integrating with GitHub, so we will
# use S3 as if it was a source repository and we'll put our Dockerfile
# there.

resource "aws_s3_bucket" "fake_github" {
    bucket_prefix = "${var.environment_name}-fake-github-"
    force_destroy = true
}

resource "aws_s3_bucket_versioning" "fake_github" {
  bucket = aws_s3_bucket.fake_github.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "archive_file" "web_to_pdf_dockerfile" {
  type        = "zip"
  output_path = "${path.module}/web_to_pdf.zip"

  source {
    filename = "Dockerfile"
    content = <<DOCKERFILE
FROM mendhak/http-https-echo:31
RUN echo This is the web-to-pdf Docker image.
DOCKERFILE
  }
}

resource "aws_s3_object" "web_to_pdf_dockerfile" {
  bucket = aws_s3_bucket.fake_github.bucket
  key    = "web_to_pdf/Dockerfile"
  source = data.archive_file.web_to_pdf_dockerfile.output_path
}

resource "aws_codepipeline" "web_to_pdf" {
  name     = "${var.environment_name}-web-to-pdf"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

# In the real world, this would be a connection to a repository such as GitHub.
# But in the context of this exercise, we'll skip this and use S3 instead.
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = aws_s3_bucket.fake_github.bucket
        S3ObjectKey = "web_to_pdf/Dockerfile"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["imagedefinitions"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.web_to_pdf.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefinitions"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.default.name
        ServiceName = aws_ecs_service.web_to_pdf.name
        FileName    = "imagedefinitions.json"
        DeploymentTimeout = 15 # minute
      }
    }
  }
}

data "archive_file" "svg_to_pdf_dockerfile" {
  type        = "zip"
  output_path = "${path.module}/svg_to_pdf.zip"

  source {
    filename = "Dockerfile"
    content = <<DOCKERFILE
FROM mendhak/http-https-echo:31
RUN echo This is the svg-to-pdf Docker image.
DOCKERFILE
  }
}

resource "aws_s3_object" "svg_to_pdf_dockerfile" {
  bucket = aws_s3_bucket.fake_github.bucket
  key    = "svg_to_pdf/Dockerfile"
  source = data.archive_file.svg_to_pdf_dockerfile.output_path
}

resource "aws_codepipeline" "svg_to_pdf" {
  name     = "${var.environment_name}-svg-to-pdf"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

# In the real world, this would be a connection to a repository such as GitHub.
# But in the context of this exercise, we'll skip this and use S3 instead.
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = aws_s3_bucket.fake_github.bucket
        S3ObjectKey = "svg_to_pdf/Dockerfile"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["imagedefinitions"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.svg_to_pdf.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefinitions"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.default.name
        ServiceName = aws_ecs_service.svg_to_pdf.name
        FileName    = "imagedefinitions.json"
        DeploymentTimeout = 15 # minute
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket_prefix = "${var.environment_name}-codepipeline-"
  force_destroy = true
  tags = {
    Name = "${var.environment_name}-codepipeline"
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "codepipeline_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.environment_name}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    sid = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      # The bucket where Codepipeline stores its artifacts and passes them around between stages
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",

      # The bucket which we are using as a fake-GitHub and storing our Dockerfiles
      aws_s3_bucket.fake_github.arn,
      "${aws_s3_bucket.fake_github.arn}/*"
    ]
  }

  statement {
    sid = "CodebuildAccess"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

  statement {
    # See the ECS section https://docs.aws.amazon.com/codepipeline/latest/userguide/security-iam.html#how-to-custom-role
    sid = "DeployToECS"
    effect = "Allow"
    actions = [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:TagResource",
        "ecs:UpdateService",
    ]
    # resources = [aws_ecs_service.web_to_pdf.id]
    resources = ["*"]
  }

  statement {
    # See the ECS section https://docs.aws.amazon.com/codepipeline/latest/userguide/security-iam.html#how-to-custom-role
    sid = "DeployToECSPassRole"
    effect = "Allow"
    actions = [
        "iam:PassRole",
    ]
    resources = [aws_iam_role.ecs_execution_role.arn]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.environment_name}-codepipeline"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}
