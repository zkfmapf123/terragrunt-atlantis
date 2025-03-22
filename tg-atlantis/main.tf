variable "atlantis_attr" {
  type = object({

    ## network
    vpc_id     = string
    subnet_ids = list(string)
    alb_sg_id  = string

    ## ecs setting
    cluster_name = string
    name         = string
    port         = string
    image_arn    = string
    is_public_ip = bool

    ## lb setitng
    priority        = string
    host_header     = list(string)
    lb_listener_arn = string


    ## ssm setting
    gh_user               = string
    repo_allowlist        = string
    ssm_gh_token          = string
    ssm_gh_webhook_secret = string

    ## aws setting
    ssm_aws_access_key_id        = string
    ssm_aws_secret_access_key_id = string
  })

}

#################################################### Listner Target Group ####################################################
resource "aws_lb_target_group" "atlantis_ecs_tg" {
  name        = "${var.atlantis_attr.name}-tg"
  port        = var.atlantis_attr.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.atlantis_attr.vpc_id

  health_check {
    path                = "/"
    port                = var.atlantis_attr.port
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-301"
    timeout             = 30
    interval            = 40
  }

  deregistration_delay = 60
}

resource "aws_lb_listener_rule" "atlantis_443_rule" {
  listener_arn = var.atlantis_attr.lb_listener_arn
  priority     = var.atlantis_attr.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.atlantis_ecs_tg.arn
  }

  condition {
    host_header {
      values = var.atlantis_attr.host_header
    }
  }
}


#################################################### Atlantis ####################################################
module "atlantis" {
  source = "terraform-aws-modules/atlantis/aws"

  name = var.atlantis_attr.name

  # ECS Container Definition
  atlantis = {
    image = var.atlantis_attr.image_arn
    environment = [
      {
        name  = "ATLANTIS_GH_USER"
        value = var.atlantis_attr.gh_user
      },
      {
        name = "ATLANTIS_REPO_ALLOWLIST"
        // single : github.com/[inc-name]/[repo-name]
        // multi : github.com/[inc-name]/[repo-name],github.com/[inc-name]/[repo-name]
        value = var.atlantis_attr.repo_allowlist
      },
      {
        name : "ATLANTIS_REPO_CONFIG_JSON",
        value : jsonencode(yamldecode(file("${path.module}/server-atlantis.yaml"))),
      }
    ]
    secrets = [
      {
        name      = "ATLANTIS_GH_TOKEN"
        valueFrom = var.atlantis_attr.ssm_gh_token
      },
      {
        name      = "ATLANTIS_GH_WEBHOOK_SECRET"
        valueFrom = var.atlantis_attr.ssm_gh_webhook_secret
      },
      {
        name      = "AWS_ACCESS_KEY_ID"
        valueFrom = var.atlantis_attr.ssm_aws_access_key_id
      },
      {
        name      = "AWS_SECRET_ACCESS_KEY"
        valueFrom = var.atlantis_attr.ssm_aws_secret_access_key_id
      },
    ]
  }

  # ECS Service
  service = {
    assign_public_ip = var.atlantis_attr.is_public_ip
    task_exec_secret_arns = [
      var.atlantis_attr.ssm_gh_token,
      var.atlantis_attr.ssm_gh_webhook_secret,
      var.atlantis_attr.ssm_aws_access_key_id,
      var.atlantis_attr.ssm_aws_secret_access_key_id,
    ]
    # Provide Atlantis permission necessary to create/destroy resources
    tasks_iam_role_policies = {
      AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
  }
  service_subnets = var.atlantis_attr.subnet_ids
  vpc_id          = var.atlantis_attr.vpc_id

  # Cluster
  create_cluster = false
  cluster_arn    = var.atlantis_attr.cluster_name

  # ALB
  create_alb            = false
  alb_target_group_arn  = aws_lb_target_group.atlantis_ecs_tg.arn
  alb_security_group_id = var.atlantis_attr.alb_sg_id

  tags = {
    System = "ecs"
  }
}
