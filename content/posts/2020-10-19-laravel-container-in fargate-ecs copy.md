---
title: 'Laravel Jetstream in Fargate ECS'
draft: true
date: 2020-10-19T20:47:51-08:00
author: Ed Anisko
layout: post
categories:
  - CloudFormation
  - AWS
  - PHP
---
There's a lot of PHP code out there.  Wordpress, Drupal, Zend, Laravel.  These are just a few of the untold endless frameworks out there.  Even so, PHP has conspicuously been left out of the buzzword rich, serverless revolution.  Today's PHP developer might be asking, am I the last. A remaining holdout of a simpler, more complicated time.  It may be.  Surely the last ALGOL developer questioned the end before it came.

All of this PHP code has to go somewhere.  Cramming it into a Lambda function is just too messy.  There is Docker.  Docker is pretty great.  But up until now, Docker, in real life, meant managing a cluster.  Managing a cluster is not pretty great.   AWS Fargate ECS removes the cluster pain and makes Docker... serverless.

Follow along to create a raw Laravel Jetstream installation as a single task.  Get it to work on first on a dev machine and then in Fargate.  

#### Requirements:
- Docker [install](https://docs.docker.com/desktop/)
- NodeJS [install](https://nodejs.com)
- AWS Account [here](https://aws.amazon.com/)



#### Roadmap

- Create a Laravel capable docker container
- Create a local Laravel project using docker
- Create a production ready image
- Release to Fargate ECS



### Create the PHP Docker Container

First check if docker is installed properly.
```
docker run hello-world
```
Docker will download something and you should see a Hello from Docker! message in your terminal.


Create a new directory somewhere on your terminal.
```sh
cd ~/ && mkdir phplaravel && cd phplaravel
```
This will create a directory in your home folder named phplaravel.  Create an infrastructure directory to keep this code separated from the rest of the application.  Call the directory infra for short. 

Inside the infra directory create a file named Dockerfile. The tree stucture will so far looks like this. 

```sh
phplaravel
└── infra
    └── Dockerfile
 ```






Add the following commands to the Dockerfile. 
Dockerfile
```docker
FROM composer

RUN apk update && apk add nodejs npm
```

The Dockerfile will start off using the latest composer container provided in the docker containter repository.  Next it installs a few packages that Laravel will need to run.  



Build the image, login and take a look inside.
```sh
docker build -t phplaravel:latest -f infra/Dockerfile .

docker run --rm -it  phplaravel:latest bash

bash-5.0# php -v
PHP 7.4.11 (cli) (built: Oct  1 2020 20:01:20) ( NTS )
Copyright (c) The PHP Group
Zend Engine v3.4.0, Copyright (c) Zend Technologies

exit
```

This step is complete.  This container has all that is needed to create, edit and run a tutorialized, dockerized version of Laravel Jetstream.

---













### Create A Local Laravel Project In Docker

The image is capable of running a dev version of Laravel.  This is a pared down, no frills version of Laravel but it does work.  To create a Laravel project on the host, that can be edited and run inside the container, follow along.


```
docker run --name phplaravel-container \
    --volume $(pwd):/phplaravel \
    -p 8888:8888 \
    -t -d --entrypoint /bin/bash phplaravel
```

The output will be a hash that looks something like this. 

d48565a9776120112b301489893565ee37cd076fc744b7ef29865dcb48a4f71b

Ignore it and login to the container.

```
docker exec -it phplaravel-container bash
```

Once inside the container, the command prompt will look like this.
```
bash-5.0# 
```

Switch to the /phplaravel directory and create a new Laravel project.
```
cd /phplaravel/

composer create-project --prefer-dist laravel/laravel laravel

cd laravel && composer require laravel/jetstream

php artisan jetstream:install inertia --teams

npm install && npm run dev
```

On the host machine there will be a new directory named **laravel**.  Make changes in this directory and those changes will be present inside the docker container.  This is a working dev version of Laravel Jetstream.  Almost.  

The app still needs a database.  To add one change the .env file and create a sqlite database following the instructions below.  First open the project in an editor.

Change the database section of the .env file.  

It starts off looking like this.
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=
```

Remove those lines and replace it with this one line.
```
DB_CONNECTION=sqlite
```

Next create a new, empty file named database.sqlite in the database directory of the Laravel project. 
```
touch /phplaravel/laravel/database/database.sqlite
```

Back in the terminal of the docker instance migrate the database.  Then, serve the project.
```
php artisan migrate

php artisan serve --port 8888 --host 0.0.0.0
```

Open your browser and play around with you local docker dev version of Jetstream. <a href="http://localhost:8888" target="_blank">Click</a>

Configure Jetstream according to their docs. <a href="https://jetstream.laravel.com/" target="_blank">Jetstream</a>

Pretty good right?

CTRL-C to turn off your server or open another terminal to continue working inside docker. All composer packages and npm packages should be added inside the container.

```
docker exec -it phplaravel-container bash
```

---
















.

.

.








### Create A Production Ready Image

Making a production ready image is going to coincide with the creation of a production architecure.  To define a split between development and production. Make a prod directory inside the infra directory. Create the following files.

template.yml
```yml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'cfn-modules: Fargate ALB to single container example'
Resources:
  Alerting:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        Email: 'email@domain.com' # replace with your email address to receive alerts
        # HttpsEndpoint: 'https://api.marbot.io/v1/endpoint/xyz' # or uncommnet and receive alerts in Slack or Microsoft Teams using marbot.io
      TemplateURL: './node_modules/@cfn-modules/alerting/module.yml'
  Key:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        AlertingModule: !GetAtt 'Alerting.Outputs.StackName'
      TemplateURL: './node_modules/@cfn-modules/kms-key/module.yml'
  DatabaseSecret:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        KmsKeyModule: !GetAtt 'Key.Outputs.StackName'
        Description: !Sub '${AWS::StackName}: database password'
      TemplateURL: './node_modules/@cfn-modules/secret/module.yml'      
  Vpc:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        AlertingModule: !GetAtt 'Alerting.Outputs.StackName'
        S3Endpoint: 'false' # speed up the example
        DynamoDBEndpoint: 'false' # speed up the example
        FlowLog: 'false' # speed up the example
        NatGateways: 'false' # speed up the example
      TemplateURL: './node_modules/@cfn-modules/vpc/module.yml'
  #############################################################################
  #                                                                           #
  #                               DynamoDB Cache                              #
  #                                                                           #
  #############################################################################  
  LaravelCache:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        PartitionKeyName: id # optional
        PartitionKeyType: S # optional
        BillingAndScalingMode: PROVISIONED # optional
        MaxWriteCapacityUnits: '1' # optional
        MinWriteCapacityUnits: '1' # optional
        WriteCapacityUnitsUtilizationTarget: '80' # optional
        MaxReadCapacityUnits: '1' # optional
        MinReadCapacityUnits: '1' # optional
        ReadCapacityUnitsUtilizationTarget: '80' # optional
        StreamViewType: DISABLED # optional
        BackupRetentionPeriod: '30' # optional            
      TemplateURL: './node_modules/@cfn-modules/dynamodb-table/module.yml'
  
  #############################################################################
  #                                                                           #
  #                      RDS Auroa Serverless resources                       #
  #                                                                           #
  #############################################################################      
  AuroraServerlessClientSg:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        VpcModule: !GetAtt 'Vpc.Outputs.StackName'
      TemplateURL: './node_modules/@cfn-modules/client-sg/module.yml'
  AuroraServerlessCluster:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        VpcModule: !GetAtt 'Vpc.Outputs.StackName'
        ClientSgModule: !GetAtt 'AuroraServerlessClientSg.Outputs.StackName'
        KmsKeyModule: !GetAtt 'Key.Outputs.StackName'
        AlertingModule: !GetAtt 'Alerting.Outputs.StackName'
        SecretModule: !GetAtt 'DatabaseSecret.Outputs.StackName'
        DBName: laravel
        DBMasterUsername: master
        AutoPause: 'true'
        SecondsUntilAutoPause: '900'
        MinCapacity: '1'
        MaxCapacity: '2'
        EngineVersion: '5.7.mysql-aurora.2.07.1'
      TemplateURL: './node_modules/@cfn-modules/rds-aurora-serverless/module.yml'      
  #############################################################################
  #                                                                           #
  #                   Application load balancer resources                     #
  #                                                                           #
  #############################################################################      
  Alb:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        VpcModule: !GetAtt 'Vpc.Outputs.StackName'
        AlertingModule: !GetAtt 'Alerting.Outputs.StackName'
      TemplateURL: './node_modules/@cfn-modules/alb/module.yml'
  AlbListener:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        AlbModule: !GetAtt 'Alb.Outputs.StackName'
      TemplateURL: './node_modules/@cfn-modules/alb-listener/module.yml'
  LaravelTarget:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        AlbModule: !GetAtt 'Alb.Outputs.StackName'
        AlbListenerModule: !GetAtt 'AlbListener.Outputs.StackName'
        VpcModule: !GetAtt 'Vpc.Outputs.StackName'
        AlertingModule: !GetAtt 'Alerting.Outputs.StackName'
      TemplateURL: './node_modules/@cfn-modules/ecs-alb-target/module.yml'
  #############################################################################
  #                                                                           #
  #                         ECS / Fargate resources                           #
  #                                                                           #
  #############################################################################    
  Cluster:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      TemplateURL: './node_modules/@cfn-modules/ecs-cluster/module.yml'    
  LaravelService:
    Type: 'AWS::CloudFormation::Stack'
    Properties:
      Parameters:
        VpcModule: !GetAtt 'Vpc.Outputs.StackName'
        ClusterModule: !GetAtt 'Cluster.Outputs.StackName'
        TargetModule: !GetAtt 'LaravelTarget.Outputs.StackName'
        AlertingModule: !GetAtt 'Alerting.Outputs.StackName'
        ClientSgModule1: !GetAtt 'AuroraServerlessClientSg.Outputs.StackName'
        ProxyImage: !Ref ProxyImage
        ProxyPort: '80'
        AppImage: !Ref AppImage
        AppPort: '8000'
        AppEnvironment1Key: 'DATABASE_PASSWORD'
        AppEnvironment1SecretModule: !GetAtt 'DatabaseSecret.Outputs.StackName'
        AppEnvironment2Key: 'DATABASE_HOST'
        AppEnvironment2Value: !GetAtt 'AuroraServerlessCluster.Outputs.DnsName'
        AppEnvironment3Key: 'DATABASE_NAME'
        AppEnvironment3Value: 'laravel'
        AppEnvironment4Key: 'DATABASE_USER'
        AppEnvironment4Value: 'master'
        Cpu: '0.25'
        Memory: '0.5'
        DesiredCount: '2'
        MaxCapacity: '4'
        MinCapacity: '2'
        LogsRetentionInDays: '14'
      TemplateURL: './node_modules/@cfn-modules/fargate-service/module.yml'
Outputs:
  Url:
    Value: !Sub 'http://${Alb.Outputs.DnsName}'
```

package.json
```javascript
{
  "dependencies": {
    "@cfn-modules/alb": "^1.0.4",
    "@cfn-modules/alb-listener": "^1.2.0",
    "@cfn-modules/alerting": "^1.2.1",
    "@cfn-modules/client-sg": "^1.0.0",
    "@cfn-modules/dynamodb-table": "^1.6.0",
    "@cfn-modules/ecs-alb-target": "^1.3.0",
    "@cfn-modules/ecs-cluster": "^1.1.0",
    "@cfn-modules/fargate-service": "^2.8.0",
    "@cfn-modules/kms-key": "^1.2.1",
    "@cfn-modules/rds-aurora-serverless": "^1.6.0",
    "@cfn-modules/secret": "^1.3.0",
    "@cfn-modules/vpc": "^1.3.0"
  }
}
```

The template is using cfn-modules to control the cloudformation build. Use npm to install the template dependencies.

```
npm i
```

 

































---

























```
docker rm phplaravel-container -f

docker build -t phplaravel:latest -f Dockerfile .

docker run --name phplaravel-container  -t -d phplaravel

docker exec -it phplaravel-container bash 
```



## Fargate

- create aws directory
- install cfn modules
- docker login to ecr 

```
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 541286214792.dkr.ecr.us-east-2.amazonaws.com

aws ecr create-repository --repository-name phplaravel

{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-2:541286214792:repository/phplaravel",
        "registryId": "541286214792",
        "repositoryName": "phplaravel",
        "repositoryUri": "541286214792.dkr.ecr.us-east-2.amazonaws.com/phplaravel",
        "createdAt": "2020-10-24T12:52:35-07:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}

aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 541286214792.dkr.ecr.us-east-2.amazonaws.com

docker build -t phplaravel .

docker tag phplaravel:latest 541286214792.dkr.ecr.us-east-2.amazonaws.com/phplaravel:latest

docker push 541286214792.dkr.ecr.us-east-2.amazonaws.com/phplaravel:latest

# interating updates
docker build -t phplaravel -f infra/prod/Dockerfile .

```

- build cloudformation and deploy

- get the out put URL from the stack

- its working

## Update the container

That's a serverless docker container that spins up from our image.  Let's change the home view and update.


app/resources/views/welcome.blade.php
```
Laravel Container - Fargate ECS
```

- rebuild the container locally

```
docker build -t phplaravel -f infra/prod/Dockerfile .
```

- push the latest out to ECR

```
docker tag phplaravel:latest 541286214792.dkr.ecr.us-east-2.amazonaws.com/phplaravel:latest
```

- create a new 











