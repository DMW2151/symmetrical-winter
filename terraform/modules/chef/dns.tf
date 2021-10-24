
# [TODO] - There should be an A record for `chef.{var.domain}`, for this demo it's excluded 
# Because We do not terminate SSL for this subdomain - use the EC2 instance DNS addr

data "aws_route53_zone" "primary" {
  name         = var.target_domain
  private_zone = false
}

resource "aws_route53_record" "maphub_nb_cname_record" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "notebooks.${var.target_domain}"
  type    = "A"
  ttl     = "300"
  records = [
    aws_instance.hub-leader.public_ip
  ]
}
