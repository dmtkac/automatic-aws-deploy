locals {
  use_domain_name = var.domain_name != "***" && var.domain_name != ""
}

resource "aws_route53_zone" "web_app_zone" {
  count = local.use_domain_name ? 1 : 0
  name  = var.domain_name
}

resource "aws_route53_record" "web_app_record" {
  count  = local.use_domain_name ? 1 : 0
  zone_id = aws_route53_zone.web_app_zone[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.web_app_alb.dns_name
    zone_id                = aws_lb.web_app_alb.zone_id
    evaluate_target_health = true
  }
}
