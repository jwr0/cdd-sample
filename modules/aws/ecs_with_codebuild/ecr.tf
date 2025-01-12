resource "aws_ecr_repository" "web_to_pdf" {
  name                 = "${var.environment_name}-web-to-pdf"
  force_delete         = true # So you can `terraform destroy` without having to delete all the images first
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # This would probably be used in a real production environment. Not needed for a sample.
  }
}

resource "aws_ecr_repository" "svg_to_pdf" {
  name                 = "${var.environment_name}-svg-to-pdf"
  force_delete         = true # So you can `terraform destroy` without having to delete all the images first
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # This would probably be used in a real production environment. Not needed for a sample.
  }
}