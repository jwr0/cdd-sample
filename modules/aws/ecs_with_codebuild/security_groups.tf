resource "aws_security_group" "web_to_pdf_load_balancer" {
  name        = "${var.environment_name}-web-to-pdf-load-balancer"
  description = "Allow HTTPS to the ${var.environment_name}-web-to-pdf load balancer"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "${var.environment_name}-web-to-pdf-load-balancer"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_to_pdf_load_balancer" {
  for_each = { for rule in [
    {
        index_name = "https_from_internet"
        cidr_ipv4 = "0.0.0.0/0"
        ip_protocol = "tcp"
        from_port = 443
        to_port = 443
        description = "Allow HTTPS to the web-to-pdf load balancer"
    }
  ] : rule.index_name => rule }
  cidr_ipv4 = lookup(each.value, "cidr_ipv4", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  ip_protocol = lookup(each.value, "ip_protocol", null)
  from_port = lookup(each.value, "from_port", null)
  to_port = lookup(each.value, "to_port", null)
  security_group_id = aws_security_group.web_to_pdf_load_balancer.id
  description = lookup(each.value, "description", null)
}

resource "aws_vpc_security_group_egress_rule" "web_to_pdf_load_balancer" {
  for_each = { for rule in [
    {
        index_name = "https_to_containers"
        referenced_security_group_id = aws_security_group.web_to_pdf_containers.id
        ip_protocol = "tcp"
        from_port = 443
        to_port = 443
        description = "Allow HTTPS to the web-to-pdf load balancer"
    }
  ] : rule.index_name => rule }
  cidr_ipv4 = lookup(each.value, "cidr_ipv4", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  ip_protocol = lookup(each.value, "ip_protocol", null)
  from_port = lookup(each.value, "from_port", null)
  to_port = lookup(each.value, "to_port", null)
  security_group_id = aws_security_group.web_to_pdf_load_balancer.id
  description = lookup(each.value, "description", null)
}

resource "aws_security_group" "web_to_pdf_containers" {
  name        = "${var.environment_name}-web-to-pdf-containers"
  description = "Allow HTTPS to the ${var.environment_name}-web-to-pdf containers"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "${var.environment_name}-web-to-pdf-containers"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_to_pdf_containers" {
  for_each = { for rule in [
    {
        index_name = "https_from_load_balancer"
        referenced_security_group_id = aws_security_group.web_to_pdf_load_balancer.id
        ip_protocol = "tcp"
        from_port = 443
        to_port = 443
        description = "Allow HTTPS from the web-to-pdf load balancer"
    }
  ] : rule.index_name => rule }
  cidr_ipv4 = lookup(each.value, "cidr_ipv4", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  ip_protocol = lookup(each.value, "ip_protocol", null)
  from_port = lookup(each.value, "from_port", null)
  to_port = lookup(each.value, "to_port", null)
  security_group_id = aws_security_group.web_to_pdf_containers.id
  description = lookup(each.value, "description", null)
}

resource "aws_vpc_security_group_egress_rule" "web_to_pdf_containers" {
  for_each = { for rule in [
    {
        index_name = "https_to_internet"
        cidr_ipv4 = "0.0.0.0/0"
        ip_protocol = "tcp"
        from_port = 443
        to_port = 443
        description = "Allow Fargate tasks to pull Docker images from ECR"
    }
  ] : rule.index_name => rule }
  cidr_ipv4 = lookup(each.value, "cidr_ipv4", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  ip_protocol = lookup(each.value, "ip_protocol", null)
  from_port = lookup(each.value, "from_port", null)
  to_port = lookup(each.value, "to_port", null)
  security_group_id = aws_security_group.web_to_pdf_containers.id
  description = lookup(each.value, "description", null)
}

