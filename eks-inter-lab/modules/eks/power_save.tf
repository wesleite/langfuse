resource "aws_ssm_parameter" "eks_nodegroup_config" {
  for_each = var.power_save_enabled ? var.eks_managed_node_groups : {}

  name  = "/eks/${var.cluster_name}/${each.key}/nodegroup_config"
  type  = "String"
  value = jsonencode({
    scaling = {
      min     = each.value.min_size
      max     = each.value.max_size
      desired = each.value.desired_size
    },
    # Trata de forma segura os labels se forem nulos ou omitidos
    labels = try(each.value.labels, null) != null ? each.value.labels : {},

    # Proteção total contra objetos de taints nulos/vazios antes de chamar a função values()
    taints = try(each.value.taints, null) != null ? [
      for t in values(each.value.taints) : {
        key    = t.key
        value  = t.value
        effect = t.effect
      }
    ] : []
  })
}

resource "aws_lambda_function" "eks_power_save" {
  count            = var.power_save_enabled ? 1 : 0
  function_name    = "eks-power-save-${var.cluster_name}"
  filename         = "${path.module}/power_save/lambda.zip"
  handler          = "eks_power_save.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_eks_power_save[0].arn
  timeout          = 300
  source_code_hash = filebase64sha256("${path.module}/power_save/lambda.zip")

  environment {
    variables = {
      CLUSTER_PREFIX      = var.cluster_name
      SLOGGER_CONTEXT     = "devops"
      SLOGGER_ENVIRONMENT = var.environment
    }
  }

  vpc_config {
    subnet_ids         = local.eks_subnet_ids
    security_group_ids = [aws_security_group.eks_power_save_sg[0].id]
  }

  layers = [
    "arn:aws:lambda:${data.aws_region.current.name}:654654517121:layer:slogger-extension:17"
  ]
}

resource "aws_security_group" "eks_power_save_sg" {
  count       = var.power_save_enabled ? 1 : 0
  name        = "eks-power-save-sg-${var.cluster_name}"
  description = "Security Group for Lambda eks-power-save"
  vpc_id      = data.aws_vpc.selected.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-power-save-sg-${var.cluster_name}"
  }
}

resource "aws_iam_role" "lambda_eks_power_save" {
  count = var.power_save_enabled ? 1 : 0
  name  = "lambda-eks-power-save-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_eks_power_save_basic_execution_role" {
  count      = var.power_save_enabled ? 1 : 0
  role       = aws_iam_role.lambda_eks_power_save[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_eks_power_save_vpc_access_execution_role" {
  count      = var.power_save_enabled ? 1 : 0
  role       = aws_iam_role.lambda_eks_power_save[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_eks_power_save_policy" {
  count = var.power_save_enabled ? 1 : 0
  name  = "eks-power-save-policy-${var.cluster_name}"
  role  = aws_iam_role.lambda_eks_power_save[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:UpdateNodegroupConfig"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["ssm:GetParameter"]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:*:*:parameter/eks/${var.cluster_name}/*"
      }
    ]
  })
}

# --- REGRAS DO EVENTBRIDGE COM SUPORTE A SUSPENSÃO (PAUSA) ---

resource "aws_cloudwatch_event_rule" "eks_power_save_scale_down" {
  count               = var.power_save_enabled ? 1 : 0
  name                = "eks-power-save-down-${var.cluster_name}"
  schedule_expression = "cron(0 23 * * ? *)"
  state               = var.power_save_suspended ? "DISABLED" : "ENABLED"
}

resource "aws_cloudwatch_event_rule" "eks_power_save_scale_up" {
  count               = var.power_save_enabled ? 1 : 0
  name                = "eks-power-save-up-${var.cluster_name}"
  schedule_expression = "cron(45 10 ? * MON-FRI *)"
  state               = var.power_save_suspended ? "DISABLED" : "ENABLED"
}

resource "aws_cloudwatch_event_target" "eks_power_save_down_target" {
  count = var.power_save_enabled ? 1 : 0
  rule  = aws_cloudwatch_event_rule.eks_power_save_scale_down[0].name
  arn   = aws_lambda_function.eks_power_save[0].arn
  input = jsonencode({ action = "down" })
}

resource "aws_cloudwatch_event_target" "eks_power_save_up_target" {
  count = var.power_save_enabled ? 1 : 0
  rule  = aws_cloudwatch_event_rule.eks_power_save_scale_up[0].name
  arn   = aws_lambda_function.eks_power_save[0].arn
  input = jsonencode({ action = "up" })
}

resource "aws_lambda_permission" "eks_power_save_allow_cwe_down" {
  count         = var.power_save_enabled ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatchDown-${var.cluster_name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eks_power_save[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eks_power_save_scale_down[0].arn
}

resource "aws_lambda_permission" "eks_power_save_allow_cwe_up" {
  count         = var.power_save_enabled ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatchUp-${var.cluster_name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eks_power_save[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eks_power_save_scale_up[0].arn
}