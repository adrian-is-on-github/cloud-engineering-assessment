# AWS defined here to clear the implied provider error message
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
data "aws_region" "current" {}

### RESOURCES ###
resource "aws_ecs_cluster" "app_cluster" {
  name = var.cluster_name
}



resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.task_definition_family}-log-group"
  tags = var.tags
}



resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.task_definition_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_definition_cpu
  memory                   = var.task_definition_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.app_ecr_repo_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.task_definition_container_port
          hostPort      = var.task_definition_host_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${var.task_definition_family}-log-group",
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "ecs"
        }
        }
    }
  ])
}



resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    assign_public_ip = true
  }

  # depends_on = [
  #   aws_route_table_association.public_assoc
  # ]
}




### IAM ###
# Pretty basic permissions for now
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.task_definition_family}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
### This could be tightened down on a per task and resource basis. Logs and ECR access for now.

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.task_definition_family}-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}



### VARS ###
variable "app_ecr_repo_url" {
  description = "The ECR repository URL"
  type        = string
}
variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}
variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}
variable "subnet_ids" {
  description = "The subnet IDs to launch the ECS service into"
  type        = list(string)
}
variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}
variable "task_definition_cpu" {
  description = "The CPU units for the ECS task definition"
  type        = string
}
variable "task_definition_family" {
  description = "The family name of the ECS task definition"
  type        = string
}
variable "task_definition_memory" {
  description = "The memory for the ECS task definition"
  type        = string
}
variable "task_definition_container_port" {
  description = "The container port for the ECS task definition"
  type        = number
}
variable "task_definition_host_port" {
  description = "The host port for the ECS task definition"
  type        = number
}