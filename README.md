# aws-cdh-spot-integration
Building up a CDH cluster(5.11.2) in AWS by using EC2 Fleet.

***The project is building in North Virginia Region(us-east-1), if you want to deploy to other regions, please modify the packer scripts and cloudformation template as needed.***

In this github project, I have tested version 5.11.2 and you might try other versions as well. Please notify me if other version works. Sincerely need your contribution to make things great!

| Cloudera Cluster Version |
|--------------------------|
| 5.11.2                   |
|                          |

### Preparation
---
- Setting up a VPC including 3+ subnets(public/private)
- Installing packer tool to build up Cloudera Manager and Cloudera Node AMI
- An AWS account in global region

### Getting Started
---
1. **Install Go environment**  
Packer depends on the Go compile environment, you have to install Go first to finish the packer installation.
Please follow the [Go Installation](https://golang.org/doc/install) instructions 

2. **Install Packer Tool**   
After finishing the installation of Go, you may start building ***Packer***.
Please follow the [Packer Installation](https://www.packer.io/intro/getting-started/install.html) instructions.

3. **Create Cloudera Manager AMI**  
Cloudera Manager is an end-to-end application for managing CDH clusters.

We will use ***Packer*** to create the ami and upload to the ami repository in your AWS account.

The Cloudera Manager AMI is created based on the CentOS 7 AMI(**ami-02eac2c0129f6376b**), you need to setup the base ami in ***cm-packer.json***
```
{
    "variables": {
      "aws_access_key": "",
      "aws_secret_key": "",
      "aws_region": "us-east-1",
      "ami_name": "cdh-cm-{{timestamp}}",
      "source_ami_id": "ami-02eac2c0129f6376b",
      "instance_type": "m4.large"
    },
    "builders": [
      {
        "type": "amazon-ebs",
        "region": "{{user `aws_region`}}",
        "source_ami": "{{user `source_ami_id`}}",
        "access_key": "{{user `aws_access_key`}}",
        "secret_key": "{{user `aws_secret_key`}}",
        "instance_type": "{{user `instance_type`}}",
        "launch_block_device_mappings": [
            {
              "device_name": "/dev/sda1",
              "volume_type": "gp2",
              "volume_size": 20,
              "delete_on_termination": true
            }
          ],
        "ssh_username": "centos",
        "ami_name": "{{user `ami_name`}}",
        "ami_description": "Cloudera cluster manager AMI with CentOS image"
      }
    ],
    "provisioners": [
      {
        "type": "shell",
        "execute_command": "sudo '{{ .Path }}'",
        "script": "cm-setup.sh"
      }
    ]
  }
```
When filling in the necessary fields, run the packer to build the ami
```
$ export AK=<Access Key>
$ export SK=<Secret Key>
$ packer build -var "aws_access_key=$AK" -var "aws_secret_key=$SK" cm-packer.json
```

Once finished, you need to record the newly created ami id displayed in the console
```
==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:
us-east-1: ami-xxx
```

4. **Create Cloudera DataNode AMI**  
Similar steps need to be executed as creating CM ami, you need to setup the neccessary fields such as region and base ami id in **node-packer.json**.

When filling in the necessary fields, run the packer to build the ami
```
$ export AK=<Access Key>
$ export SK=<Secret Key>
$ packer build -var "aws_access_key=$AK" -var "aws_secret_key=$SK" node-packer.json
```
Once finished, you need to record the newly created ami id displayed in the console
```
==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:
us-east-1: ami-xxx
```

After finishing the ami creation, you could check the ami in your account to verify whether the ami has uploaded to the ami repo
```
$ aws ec2 describe-images --image-ids <ami id>
```

5. **Running context creation template(cdh-context.yml)**   
The script is a AWS Cloudformation template and you need to open the Cloudformation service in AWS console or by using AWS CLI to create the Cloudformation Stack.The script will setup a Aurora MySQL database for CDH cluster and store the password information in [***System Manager Parameter Store***](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html) for secure consideration.

6. **Running Cloudera Cluster cration template**. 
Create a new Cloudformation Stack to launch the CM and DataNode in EC2 Fleet.

The template has already setup a AutoScaling group to dynamically increase or decrease the nodes in the cluster. You might setup a scaling policy in the Cloudformation template as you like.

There are several places you need to modify in the template

- AMI mapping
```
Mappings:
  AWSRegionToCDHAMI:
    <**Region**>:
      CMAMIID: <**Cloudera Manager AMI ID**>
      CDHNODEAMIID: <**Cloudera DataNode AMI ID**>
```
- cm-mgmt-svc-setup.py (upload to S3 or other public storage)
```
curl -s -o /tmp/cm-mgmt-svc-setup.py <URL of cm-mgmt-svc-setup.py>
```
- cluster_template.json
```
curl -s -o /tmp/cluster_template.json <URL of cm-mgmt-svc-setup.py>
```

You could modify the autoscaling configuration to setup the node types and percentage of on-demand instances.
```
AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      MixedInstancesPolicy:
        LaunchTemplate:
          LaunchTemplateSpecification:
            LaunchTemplateId: !Ref CDHLaunchTemplate
            Version: !GetAtt CDHLaunchTemplate.LatestVersionNumber
          Overrides:
            - InstanceType: m4.xlarge
            - InstanceType: r4.xlarge
        InstancesDistribution:
          OnDemandPercentageAboveBaseCapacity: 0
      MinSize: 3
      MaxSize: 10
      DesiredCapacity: !Ref 'CDHNodesCapacity'
      VPCZoneIdentifier: !Ref FleetSubnets
```

7. **Wrap Up**
Once the stack is created completely, the Cloudera Cluster is able to run in your EC2 Fleet.

You could adjust the autoscaling group to setup the min/max size of the fleet or the percentage of the on-damand instances.

***IMPORTANT***
Please be aware that you have to guarantee there are adequate node to run the management components such as NameNode and Yarn to ensure the cluster is running well.


