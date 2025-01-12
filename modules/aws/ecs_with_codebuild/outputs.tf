output "web_to_pdf_hostname" {
  value = aws_lb.web_to_pdf_external.dns_name
}

output "svg_to_pdf_hostname" {
  value = aws_lb.svg_to_pdf_external.dns_name
}
