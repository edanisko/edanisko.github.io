---
title: 'Laravel Containers in Fargate ECS'
date: 2020-10-15T20:47:51-08:00
author: Ed Anisko
layout: post
categories:
  - CloudFormation
  - AWS
  - PHP
---
There's a lot of code in PHP out there.  Wordpress, Drupal, Zend Framework, Code Igniter, Laravel there are endless frameworks.  PHP has conspicuously been left out of the buzzword rich serverless revolution.  Strange, since roughly half of the internet is running PHP.  Even the dying Ruby language has native AWS Lambda support.  No PHP.  That's ok.  I don't care which language I am required to use on a project.  However, I do care about a few favorite projects that I've written and maintained over the years that are being left behind.

It's actually as bad as it sounds.  Support for PHP in serverless architecture is pretty easy to achieve using Docker.  Under the hood Lambda is really just Amazon Linux and Docker.  You can create a lambda wrapper for PHP and run your code as you would if you were using Python.  In this article we will setup a Laravel PHP project and get it out to Fargate ECS and see it working on the internet. 

Requirements:
- Docker (install)

There is a bit of a chicken and the egg problem with Laravel.  PHP can be and is installed as a default on many computers.  Just as many other OS versions do not include PHP.  Laravel is a lot easier to using the composer package, so much so that it is a defacto requirement.  Instead of making PHP and composer a requirement to the base system, we will just create a system inside docker that has what it needs to complete the build steps.

Check to see that docker is installed and working. Open your terminal.

```
docker run hello-world
```

Docker will download something and you should see a Hello from Docker! message in your terminal.

For fun, while your terminal is open, you can see what version if any of PHP is installed on your system.

```
php --version

PHP 7.4.11 (cli) (built: Oct  1 2020 23:30:54) ( NTS )
Copyright (c) The PHP Group
Zend Engine v3.4.0, Copyright (c) Zend Technologies
    with Zend OPcache v7.4.11, Copyright (c), by Zend Technologies
```
My system has PHP 7.4.11 installed.  It shows the following while your system will likely show something different.

We need a system that we know will run Laravel PHP.  We also need to create a new Laravel PHP project as an example to work from.  Chicken. Egg.  First things first, we know we will need a system.  So let's start one up in docker, login there and see what that's like. 

Make a new folder somewhere on your system and change directory in to that folder. 

```sh
cd ~/ && mkdir laravelphp && cd laravelphp

```

Just to get an idea of what docker is actually doing under the hood.  Create a file named Dockerfile in this directory.  Let's right the easist Dockerfile we possibly can.

Dockerfile
```ruby
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

Great! That's docker. A little script and a couple of command lines and now you have another OS running on your local system.  It's its own little world in there that can spin up, run some php and disappear.  That's the basics of a serverless function really.  

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
composer # 
   ______
  / ____/___  ____ ___  ____  ____  ________  _____
 / /   / __ \/ __ `__ \/ __ \/ __ \/ ___/ _ \/ ___/
/ /___/ /_/ / / / / / / /_/ / /_/ (__  )  __/ /
\____/\____/_/ /_/ /_/ .___/\____/____/\___/_/
                    /_/
Composer version 1.10.13 2020-09-09 11:46:34
...
```

Great lets install Laravel.

```
composer create-project --prefer-dist laravel/laravel blog

Creating a "laravel/laravel" project at "./app"
Installing laravel/laravel (v8.1.0)
  - Installing laravel/laravel (v8.1.0): Downloading (100%)         
Created project in //app
> @php -r "file_exists('.env') || copy('.env.example', '.env');"
Loading composer repositories with package information
Updating dependencies (including require-dev)

```












