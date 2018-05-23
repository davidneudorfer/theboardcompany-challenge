output "aws_key_name" {
  value = "${var.aws_key_name}"
}

output "base_domain" {
  value = "${var.base_domain}"
}

output "zone_id" {
  value = "${data.aws_route53_zone.zone.id}"
}

output "certificate_arn" {
  value = "${aws_acm_certificate_validation.cert.certificate_arn}"
}
