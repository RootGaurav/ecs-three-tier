output "record_name" {
  value = aws_route53_record.app.name
}

output "record_fqdn" {
  value = aws_route53_record.app.fqdn
}
