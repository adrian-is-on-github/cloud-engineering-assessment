# Cloud Engineering Technical Assessment

## Overview
This assessment evaluates your proficiency with Docker, Terraform, AWS (specifically ECS), and CI/CD pipelines. You'll be containerizing a simple Python application and deploying it to AWS ECS using Terraform. If you are not familiar with any of the technologies, feel free to complete as much as you can.

## Time Expectation
This assessment should take approximately 3-4 hours to complete.

## Requirements

### Part 1: Containerization
- Containerize the provided Python Flask application
- Create an optimized Dockerfile that follows security best practices
- Ensure the container properly runs the application on port 5000

### Part 2: Infrastructure as Code
- Create Terraform configurations to deploy the application to AWS ECS
- Set up the following AWS resources:
  - VPC with public and private subnets
  - ECS Cluster (Fargate launch type)
  - ECS Task Definition and Service for the containerized application
  - All necessary security groups, IAM roles, etc.
- Feel free to use any ready-made open-source terraform modules available

### Part 3: CI/CD Implementation
- Create a CI/CD pipeline configuration using GitHub Actions
- The pipeline should:
  - Build and tag the Docker image
  - Push the image to Amazon ECR
  - Deploy the updated image to ECS

### Part 4: Documentation
- Provide a README.md with:
  - Setup and deployment instructions
  - Potential improvements for a production environment
- Optionally include a simple architecture diagram (can be created with any tool)

## Deliverables
Please provide:
1. All source code in a GitHub repository (public or private with access shared)
2. Complete Terraform configurations
3. CI/CD pipeline configuration files
4. Documentation and architecture diagram (if you have any)
5. Any additional scripts or configurations you created

## Evaluation Criteria
Your submission will be evaluated based on:
- Docker best practices (security, optimization, multi-stage builds)
- Terraform organization, structure, and best practices
- AWS resource configuration and security
- Code quality and documentation
- CI/CD pipeline effectiveness

## Optional Extensions
If you have additional time and would like to demonstrate more of your skills, consider implementing these optional features:
- Adding an Application Load Balancer to distribute traffic to your service
- Configuring CloudWatch Logs for container logging

## Files Included in This Package
1. `app/` - Directory containing the Python Flask application
   - `app.py` - The main application file
   - `requirements.txt` - Python dependencies
2. `README.md` - This file with instructions

Good luck!