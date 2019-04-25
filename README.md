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
Please follow the [Go Installation](https://golang.org/doc/install) instructions 

After finishing the installation of Go, you may start building ***Packer***
Please follow the [Packer Installation](https://www.packer.io/intro/getting-started/install.html) instructions

- Running context creation script(cdh-context.yml)
The script is a AWS Cloudformation template and you need to open the Cloudformation service in AWS console or by using AWS CLI to create the Cloudformation Stack.

The script will setup a Aurora MySQL database for CDH cluster and store the password information in [***System Manager Parameter Store***](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html) for secure consideration.

