# Cloud Engineering Technical Assessment



## Overview
- There are three main directories: */workflows, */app and */infra
* The purpose was to make it more explicit what was being changed when committing (although the commit history is rather messy for this fast P.O.C. type exercise - sry!)
* It also makes organization a bit easier when the scope of the application increases


# Architecture Diagram
- A quick auto-generated sketch is available at `graph.png` in the /infra directory.


### Who to contact for questions:
Get in touch with
- Adrian Bishop or...
- ...anyone else from the DevOps Team
- !...before deploying any resources, please



## Infra ##
```
.
├── main.tf <------------- call all modules here
├── modules <------------- add more modules here
│   ├── ecr
│   │   └── ecr.tf
│   ├── ecs
│   │   └── ecs.tf
│   └── vpc
│       └── vpc.tf
├── providers.tf <-------- define more regions here
└── variables.tf <-------- use vars.tf in new modules when they start to get complicated
```

- The infrastructure is built to be re-usable and modular. Each module can be easily repurposed, and even deployed to different regions as needed.
- I've also included the bones of implementing an RDS instance as well.
- Some resources are enabled via param value. More of this could be done if more flexibility is needed.

# Requirements:
- An S3 bucket with versioning enabled. This will be your state bucket. Configure in `providers.tf`
- Terraform
  * If on Mac, run `brew install hashicorp/tap/terraform`
- AWS CLI key
  * User should have admin permissions
  * If you have multiple AWS profiles, please run `export AWS_PROFILE=$profilename` before running any terraform commands. 
  * * Otherwise, it'll run in the default profile
  * More info on AWS CLI and profiles is here: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Deployment
- run `export AWS_PROFILE=$profilename`
- run `terraform plan`
- run `terraform apply`
- watch the magic
Once the infra is deployed, run the Github actions pipeline (click the button). Or just push a change to the /app directory and the build will be triggered automatically.

### VPC 
- The VPC module I had on hand from another project. The subnet naming and assignment was fun to build, however it's probably a little over-engineered.
- It contains networking resources and basic security groups.

### ECS ECR
The ECS and ECR modules were created for this project.
- ECS is a quick "let's get online" type example, with permissions that can be tightened down.
- * Includes container logging and security group for each service
- IAM execution role included here as well, since it may be re-used for different apps
- ECR has parameters available to adjust lifecycle configuration.


### Future Improvements
- Set specific Terraform and AWS provider versions
- Tightening NACLS, IAM roles and permissions and SGs
- Add a load balancer
- Add WAF
- Add autoscaling policies
- Trial OpenTofu for deployment
- Make it serverless?



# App #
```
.
├── app.py
├── dockerfile
└── requirements.txt
```

# Requirements
- Docker for local testing *optional*

- The app and build related resources are defined in this directory
- Werkzeug==2.0.3 was pinned to keep a library which was removed in later versions. Without it, gunicorn fails to start.
- Two stage build to leave dependency installer cruft behind

## Deployment
- Any change pushed to main branch in the /app directory will trigger a build/deploy
- So we're only running when code changes happen
- You can also manually trigger a build in 'Build and Deploy App' GitHub Actions workflow
- Every time a new container is pushed, we set a new task def and the latest image is pulled by the service.

### Future Improvements
- A python slim container is small-ish (55MB), however next steps would be to build and test a distroless build (~25MB, no shell).
- If the app is simple enough, non-containerised options could be an option


### Who to contact for questions:
Get in touch with
- Adrian Bishop or...
- anyone else from the DevOps Team



## Requirements
### Part 1: Containerization
- Containerize the provided Python Flask application ✅
- Create an optimized Dockerfile that follows security best practices ✅
- Ensure the container properly runs the application on port 5000 ✅

### Part 2: Infrastructure as Code
- Create Terraform configurations to deploy the application to AWS ECS ✅
- Set up the following AWS resources:
  - VPC with public and private subnets ✅
  - ECS Cluster (Fargate launch type) ✅
  - ECS Task Definition and Service for the containerized application ✅
  - All necessary security groups, IAM roles, etc. ✅

### Part 3: CI/CD Implementation
- Create a CI/CD pipeline configuration using GitHub Actions ✅
- The pipeline should:
  - Build and tag the Docker image ✅
  - Push the image to Amazon ECR ✅
  - Deploy the updated image to ECS ✅

### Part 4: Documentation
- Provide a README.md with:
  - Setup and deployment instructions ✅
  - Potential improvements for a production environment ✅
- Optionally include a simple architecture diagram (can be created with any tool)

## Optional Extensions
If you have additional time and would like to demonstrate more of your skills, consider implementing these optional features:
- Adding an Application Load Balancer to distribute traffic to your service
- Configuring CloudWatch Logs for container logging ✅
