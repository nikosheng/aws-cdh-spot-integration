# aws-cdh-spot-integration
Building up a CDH cluster in AWS by using Spot Instances

***The project is building in North Virginia Region(us-east-1), if you want to deploy to other regions, please modify the packer scripts and cloudformation template as needed.***

### Preparation
---
- Setting up a VPC including 3+ subnets(public/private)
- Installing packer tool to build up Cloudera Manager and Cloudera Node AMI
- An AWS account in global region

### Getting Started
---
- Install Packer Tool 
Packer depends on the Go compile environment, you have to install Go first to finish the packer installation.
Please follow the below [Go Installation](https://golang.org/doc/install) instructions
