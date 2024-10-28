data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb" "web_app_alb" {
  name               = "web-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_app_sg.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = {
    Name = "web-app-alb"
  }
}

resource "aws_lb_target_group" "http" {
  name     = "web-app-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    protocol            = "HTTP"
    path                = "/healthcheck"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "https" {
  count    = var.ssl_certificate_arn != "" ? 1 : 0
  name     = "web-app-https"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    protocol            = "HTTPS"
    path                = "/healthcheck"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.ssl_certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.ssl_certificate_arn != "" ? [1] : []

      content {
        protocol    = "HTTPS"
        port        = "443"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.ssl_certificate_arn == "" ? [1] : []

      content {
        target_group {
          arn = aws_lb_target_group.http.arn
        }
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.ssl_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.web_app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https[count.index].arn
  }
}

resource "aws_lb_target_group_attachment" "http" {
  count             = length(aws_instance.web_app_instance)
  target_group_arn  = aws_lb_target_group.http.arn
  target_id         = aws_instance.web_app_instance[count.index].id
  port              = 80
}

resource "aws_lb_target_group_attachment" "https" {
  count             = var.ssl_certificate_arn != "" ? length(aws_instance.web_app_instance) : 0
  target_group_arn  = aws_lb_target_group.https[0].arn
  target_id         = aws_instance.web_app_instance[count.index].id
  port              = 443
}