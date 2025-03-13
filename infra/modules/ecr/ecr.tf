# AWS defined here to clear the implied provider error message
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_ecr_repository" "ecr" {
  name                 = var.ecr_repo_name
  image_tag_mutability = var.image_tag_mutability

  encryption_configuration {
    encryption_type = "AES256"
  }
  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "flask_app_policy" {
  repository = var.ecr_repo_name
  depends_on = [aws_ecr_repository.ecr]
  policy = jsonencode(
    {
      "rules" : [
        {
          "rulePriority" : 1,
          "description" : "Expire images older than ${var.expiration_days} days",
          "selection" : {
            "tagStatus" : "any",
            "countType" : "sinceImagePushed",
            "countUnit" : "days",
            "countNumber" : var.expiration_days
          }
          "action" : {
            "type" : "expire"
          }
        }
      ]
    }
  )
}



### VARS ###
variable "ecr_repo_name" {
  description = "The name of the ECR repository"
  type        = string
}
variable "image_tag_mutability" {
  description = "The tag mutability setting for the ECR repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE" # IMMUTABLE is recommended by AWS Guard Duty/Sec Hub, but makes it tough to create the task definition
}
variable "expiration_days" {
  description = "Number of days before an image expires"
  type        = number
  default     = 30
}
variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
}



### OUTPUTS ###
output "ecr_repo_url" {
  value = aws_ecr_repository.ecr.repository_url
}
