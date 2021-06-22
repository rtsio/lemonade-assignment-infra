# Lemonade assignment infrastructure

Terraform configuration that creates AWS infrastructure to host the [Lemonade assignment](https://github.com/rtsio/lemonade-assignment). 

### Components

This Terraform configuration will create:

* network.tf
  * a VPC, public-facing subnets, internet gateway, and routing table/routes
  * Application Load Balancer listening on HTTP port 80
  * ALB target group with an HTTP healthcheck
  * security group allowing public access to the ALB from 0.0.0.0/0

* ecs.tf
  * an ECS cluster, service, and task definition (using the public Docker image for the assignment on docker.io)
  * ECS task execution role and log group/stream
  * security group allowing access from the ALB to ECS

* monitoring.tf
  * S3 bucket and corresponding policy for ALB access logs
  * CloudWatch dashboard with metrics for container resource utilization, HTTP response codes/latency, and ALB target group health

The default region is eu-central-1, this can be adjusted using variables.

Outputs: `assignment-url` contains the public DNS name of the ALB.

This is perhaps the simplest way to host a container in ECS using entirely public subnets (no private subnets/NAT). For more information
see the [AWS documentation](https://aws.amazon.com/de/blogs/compute/task-networking-in-aws-fargate/).


### Building and running

No remote state store is defined, and the container image is already hosted in a public docker.io repository.

1. Create a `secrets.tfvars`:
```yaml
aws_access_key = "..."
aws_secret_key = "..."
```
2. Run `terraform plan` and `apply`
3. After successfuly creation, you will see something along the lines of:
```
Outputs:

assignment-url = "tf-lb-20210623012109509900000005-1655038407.eu-central-1.elb.amazonaws.com"
```
Make a POST request to this URL, appending `...amazonaws.com/count` ([see API documentation](https://github.com/rtsio/lemonade-assignment)).