output "elb_dns_name" {
  value = aws_lb.web_app_alb.dns_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.web_app_bucket.bucket
}

output "instance_ids" {
  value = aws_instance.web_app_instance.*.id
}

output "azs_and_subnets" {
  value = { "azs" = data.aws_availability_zones.available.names, "subnets" = data.aws_subnets.public.ids }
}

output "instance_public_ips" {
  value = aws_instance.web_app_instance.*.public_ip
}

output "instance_public_dns" {
  value = aws_instance.web_app_instance.*.public_dns
}