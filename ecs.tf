# Security group

resource "aws_security_group" "ecs_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Allow access to ECS tasks from public ALB"

  ingress {
    protocol        = "tcp"
    from_port       = var.application_port
    to_port         = var.application_port
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ECS execution role, using default Amazon ECS policy

data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "lemonade-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ECS cluster, service, task definition

resource "aws_ecs_cluster" "main" {
  name = "lemonade-assignment-cluster"
}

resource "aws_ecs_task_definition" "main" {
  family                   = "lemonade-assignment-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions = jsonencode([{
    name        = "lemonade-container"
    image       = "${var.docker_image}"
    essential   = true
    portMappings = [{
      containerPort = var.application_port
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main.name
        awslogs-stream-prefix = "ecs"
        awslogs-region        = var.aws_region
      }
    }
  }])
}

resource "aws_ecs_service" "main" {
  name            = "lemonade-assignment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_targets.id
    container_name   = "lemonade-container"
    container_port   = var.application_port
  }

  depends_on = [aws_alb_listener.http, aws_iam_role_policy_attachment.ecs_task_execution_role_attachment]
}


# Logging

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/lemonade-assignment"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "main" {
  name           = "lemonade-assignment-log-stream"
  log_group_name = aws_cloudwatch_log_group.main.name
}
