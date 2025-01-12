resource "aws_lb" "web_to_pdf" {
  name               = "${var.environment_name}-web-to-pdf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_to_pdf_load_balancer.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.environment_name}-web-to-pdf"
  }
}

resource "aws_lb_target_group" "web_to_pdf" {
  name        = "${var.environment_name}-web-to-pdf"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = aws_vpc.default.id

  health_check {
      path                  = "/"
      protocol              = "HTTPS"
      matcher               = "200"
      port                  = "traffic-port"
      healthy_threshold     = 2
      unhealthy_threshold   = 2
      timeout               = 10
      interval              = 30
  }
}

resource "aws_lb_listener" "web_to_pdf" {
  load_balancer_arn = aws_lb.web_to_pdf.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:us-east-1:430682828307:certificate/4a1f7785-1ea5-47e0-b47e-ed1373b78420" # TODO - come back to this

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_to_pdf.arn
  }
}

resource "aws_lb" "svg_to_pdf" {
  name               = "${var.environment_name}-svg-to-pdf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.svg_to_pdf_load_balancer.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.environment_name}-svg-to-pdf"
  }
}

resource "aws_lb_target_group" "svg_to_pdf" {
  name        = "${var.environment_name}-svg-to-pdf"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = aws_vpc.default.id

  health_check {
      path                  = "/"
      protocol              = "HTTPS"
      matcher               = "200"
      port                  = "traffic-port"
      healthy_threshold     = 2
      unhealthy_threshold   = 2
      timeout               = 10
      interval              = 30
  }
}

resource "aws_lb_listener" "svg_to_pdf" {
  load_balancer_arn = aws_lb.svg_to_pdf.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:us-east-1:430682828307:certificate/4a1f7785-1ea5-47e0-b47e-ed1373b78420" # TODO - come back to this

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svg_to_pdf.arn
  }
}