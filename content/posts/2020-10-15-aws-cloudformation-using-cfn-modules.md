---
title: 'AWS CloudFormation Using CFN-Modules'
date: 2020-10-15T20:47:51-08:00
author: Ed Anisko
layout: post
categories:
  - CloudFormation
  - AWS
  - CFN-Modules
---
# 

Adding infrastructure as code to a project? The cfn-modules repositories are prebuilt scripts that will launch nested stacks in AWS Cloudformation. It's everything you hope it will be.

<!--more-->

If you have used CloudFormation you know how vast it is.  You can run just about anything you can setup in the AWS console in using a CloudFormation script.  Even more in some cases.  That's every switch and  toggle, permission, input box... everything.  It's a lot.  CFN-modules try to standardize that against AWS best practices.  

For instance, it is best practice to use a VPC when you are building your environement in AWS.  Its also best practice create a new VPC and leave the default VPC alone.  You can you use the VPC wizard in the UI, but that doesn't give you something easily repeatable.  

In the cfn-modules that best practice turns into a requirement.  There are modules for all sorts of AWS services.  The modules contain variables, some are optional and some are required.  Almost modules have a VPC requirement.  Each script will build that VPC as a nested stack using some other cfn-module.  

With cfn-modules you will be creating your own CloudFormation template just like normal.  Except with cfn-modules you will be adding modules to a project via NPM and then using the TemplateURL parameter to reference the module inside your script.

This is what it looks like in action.

## Prerequisites
* AWS CLI installed ([install](https://docs.aws.amazon.com/cli/latest/userguide/installing.html))
* npm >=5.6 installed ([install Node.js 10.x](https://nodejs.org/))

Open your project and add an infra folder to the root and change directory into that new folder.

Setup a new npm project inside the infra folder so that you will be able to use npm to add modules. 

```sh
npm init 
```

Accept the defaults. All you really need here is a package.json file with a dependencies object. You can skip the init so long as you wind up with a package.json file at minimum like the one below.

package.json
```json
{
  "dependencies": {    
  }
}
```

```sh
npm i @cfn-modules/vpc
```

Create a template.yml file.

template.yml
```yaml
---
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  Vpc:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        S3Endpoint: 'false' # speed up the example
        DynamoDBEndpoint: 'false' # speed up the example
        FlowLog: 'false' # speed up the example
        NatGateways: 'false' # speed up the example
      TemplateURL: './node_modules/@cfn-modules/vpc/module.yml'
```

Package and deploy this template and see what you get. 

Your going to need an S3 bucket to store your packaged template file.  
```
aws s3 mb s3://$YOUR_BUCKET_NAME
```

Now package your template and upload it to S3
```
aws cloudformation package --template-file template.yml --s3-bucket $YOUR_BUCKET_NAME --output-template-file packaged.yml
```

This step will add the submodules you need to the S3 bucket.  Some cfn-modules are not public facing.  Instead they are included as basic building blocks by higher order scripts.

Deploy the stack.
```
aws cloudformation deploy --template-file packaged.yml --stack-name empty-vpc --capabilities CAPABILITY_IAM
```

You can watch this empty VPC get created in the UI.  When its finished you will see something like this.

![Empty VPC in UI](/img/empty-vpc-ui.png)

Your template creates a nested stack called Vpc. Then the nesting continues. Vpc creates vpc-plain.  Vpc-plain creates other VPC level resources such as an internet gateway.  Six subnets are created, three public and three private.  The subnet resources include NACLs, route tables and routes. 

The best part is that you can repeat this is another region, another account.  This is infrastucture as code.

## Changes

If you want to add a service endpoint, change the template, re-package it and re-deploy.


template.yaml
```yaml
---
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  Vpc:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        S3Endpoint: 'true' # speed up the example
        DynamoDBEndpoint: 'false' # speed up the example
        FlowLog: 'false' # speed up the example
        NatGateways: 'false' # speed up the example
      TemplateURL: './node_modules/@cfn-modules/vpc/module.yml'
```

```
aws cloudformation package --template-file template.yml --s3-bucket YOUR_BUCKET_NAME --output-template-file updated.yml
```

```
aws cloudformation deploy --template-file updated.yml --stack-name empty-vpc
```

When this is finished you will see a new S3 service endpoint has been added to the VPC.

![Updated VPC UI](/img/updated-vpc-ui.png)

The cfn-modules include scripts for advanced infrastructure configurations like FlowLogs, ECS, Fargate, Lambda, and Serverless Aurora. You can add and iterate on your original template to get the infrastructure exactly how you want it.

Check out the cfn-modules in [here](https://github.com/cfn-modules/docs).

Don't forget to delete the VPC when you are finished.
```
aws cloudformation delete-stack --stack-name empty-vpc
```
