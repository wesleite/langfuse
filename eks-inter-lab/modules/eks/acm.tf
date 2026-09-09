data "aws_route53_zone" "domain" {
  name = var.route53_domain
}

module "acm" {
  source              = "terraform-aws-modules/acm/aws"
  version             = "~> 5.2"
  domain_name         = data.aws_route53_zone.domain.name
  zone_id             = data.aws_route53_zone.domain.zone_id
  validation_method   = "DNS"
  wait_for_validation = true

  subject_alternative_names = [
    "*.${data.aws_route53_zone.domain.name}"
  ]
}
