---
title: 'Super Simple Docker'
draft: true
date: 2020-10-19T20:47:51-08:00
author: Ed Anisko
layout: post
categories:
  - Docker
  - PHP
---
There's a lot of PHP code out there.  Wordpress, Drupal, Zend Framework, Laravel these are just a few of the endless frameworks available.  PHP has conspicuously been left out of the buzzword rich serverless revolution.  PHP developers may be asking themselves if they're the last dragons of a simpler, more complicated time.  Maybe.  Surely the last ALGOL developer questioned the end.

All that PHP code has to go somewhere.  Cramming it into a AWS Lambda function is too funky.  There is Docker.  Docker is pretty great but up until now Docker meant managing a Cluster.  Cluster management is not so great.   AWS Fargate ECS removes the cluster part and makes it serverless.  

Follow along to create a raw Laravel PHP installation as a single task in Fargate ECS.  

Requirements:
- Docker [install](https://docs.docker.com/desktop/)
- NodeJS [install](https://nodejs.com)
- AWS Account [here](https://aws.amazon.com/)



### Setup

Setting up a Laravel dev environment can be complicated and weighs alot against preference.  The target here is to setup a Laravel project, a docker docker container and put it out on ECS.  Using the docker container to create a Laravel project is the easiest way to create new project with respect to this article. The steps will be as follows:

- Create the PHP docker container
- Create a local laravel project
- Run laravel inside the container
- Release to fargate



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

```
phplaravel
└── infra
    └── Dockerfile
 ```






Next add the following text to the Dockerfile. 
Dockerfile
```sh
FROM php
```

Reading that makes docker look a lot less scary.

Go ahead and build an image.  Start a container, name it something useful. Then login using the following commands.

```
docker build -t phplaravel:latest -f Dockerfile .

docker run --name phplaravel-container  -t -d phplaravel

docker exec -it phplaravel-container bash 

```

You're command prompt looks a little different, something like this:
```
root@b887f5a66870:/#
```  

You are now logged into the the php docker distribution running on your local system.  This distribution has been downloaded from docker about 500 billion times at the time of this writing.  Welcome to this very large club.  The following commands will give you some indication of what type of system is running and which PHP is running.  

```
# php --version

PHP 7.4.11 (cli) (built: Oct 13 2020 09:55:37) ( NTS )
Copyright (c) The PHP Group
Zend Engine v3.4.0, Copyright (c) Zend Technologies
```

```
# cat /etc/*release
PRETTY_NAME="Debian GNU/Linux 10 (buster)"
NAME="Debian GNU/Linux"
VERSION_ID="10"
VERSION="10 (buster)"
VERSION_CODENAME=buster
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

Exit the docker container and go back to your command line.  Then type 
```
exit

```

If you want to see the container that is running in the background this command will show you.

```
docker ps -a

CONTAINER ID        IMAGE                                                   COMMAND                  CREATED             STATUS                      PORTS               NAMES
b887f5a66870        phplaravel                                              "docker-php-entrypoi…"   6 minutes ago       Up 6 minutes                                    phplaravel-container

```

Great! That's docker. A little script and a few commands and now you have another OS running on your local system.  It's its own little world in there that can spin up, run some php and disappear.  That's the basics of a serverless function really.  

For now we are going to use this container to create a Laravel project so that it has something interesting to run.  To do this we are going to have to add some things to the Dockerfile.

Dockerfile
```ruby
FROM php

# Install system dependencies
RUN apt-get update && apt-get install -y \
    apt-utils \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer    
```

The dockerfile is getting longer.  In this case we are going to build an image that starts off with the php distribution.  Then it will update itself, install packages laravel needs to work.  Next it copies the latest version of composer from the composer base image and puts it somewhere we can use it.  

Lets rebuild, login and take a look.

```
docker rm phplaravel-container -f

docker build -t phplaravel:latest -f Dockerfile .

docker run --name phplaravel-container  -t -d phplaravel

docker exec -it phplaravel-container bash 
```

First we destroyed the running container.  Then rebuild the latest image of phplarvel, started a new container and started a terminal window logged in as root.  Let's see if composer is working.

```
# composer
   ______
  / ____/___  ____ ___  ____  ____  ________  _____
 / /   / __ \/ __ `__ \/ __ \/ __ \/ ___/ _ \/ ___/
/ /___/ /_/ / / / / / / /_/ / /_/ (__  )  __/ /
\____/\____/_/ /_/ /_/ .___/\____/____/\___/_/
                    /_/
Composer version 1.10.13 2020-09-09 11:46:34

```

## Development
We have Docker and PHP setup with Composer.  We want to be able to run composer inside of the docker container,
then save those files into a git repository.  We could do this in a few ways.  The first way is login to the docker container and setup the git inside.  Then you can push the code out to GitHub and bring it back into your local machine, add the docker files then start copying the git repo back into docker in your build steps later on.  

The second way is to give docker access to a directory that it shares with your local system.  

This is the chicken and the egg part.  We want to create our files using the docker container but have then available to ouyr local system. To do this we will start docker using the --volume flag.

```
docker run --volume $(pwd):/root/phplaravel --name phplaravel-container -p 8000:8000 -t -d phplaravel

# or in windows

docker run --volume //c/Users/username/phplaravel:/root/phplaravel --name phplaravel-container  -t -d phplaravel
```

Now lets install Laravel inside the container.

```sh
$ cd /phplaravel

$ composer create-project --prefer-dist laravel/laravel app

Creating a "laravel/laravel" project at "./app"
Installing laravel/laravel (v8.1.0)
...
```

If you are editing your DockerFile in an IDE you will see the new app folder in your local phplaravel directory. 

```
$ cd phplaravel/app
$ php artisan serve --port 8888 --host 0.0.0.0
```

In your browser goto http://localhost:8888/ and laravel is running inside your container and exposed to the real world.

Let's make a change to the welcome blade so we know its working like we think. 

app/resources/views/welcome.blade.php
```
Laravel Container - Local Development Server
```

Save it and refresh your browser.  You should see something like the image below.
 
![Updated VPC UI](../img/fargate-ecs-1.png)


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











