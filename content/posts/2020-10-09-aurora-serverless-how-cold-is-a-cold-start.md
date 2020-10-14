---
title: 'DynamoDB - What You Need to Know'
draft: true
date: 2020-10-30T20:47:51-08:00
author: Ed Anisko
layout: post
categories:
  - Aurora Serverless
  - Cold Starts
  - AWS
tags:
  - aurora 
  - serverless 
  - 'code start'
  - php 
  - api
  - laravel  
---
# How cold are aurora serverless cold starts?

I have an api with written in PHP that I need to stand up.

It gets spikey traffic throughout the day.  But when traffic comes it needs to respond quickly.

<!--more-->

Originally the system had an ALB, with 2 small instances serving the website and processing SQS.

the back end was Aurora mysql with Elasticache for sessions.

It was sort of expensive so I need to do a little remodeling to take advantage of some of the new, serverless products that are out there now.  I want to be able to pay for processing and stop paying for idle systems.

Laravel offers Vapor.  But that solution is a bit of a black box, and its kind of expensive too. So I am going to acknowledge it, then move on.  

Lambda doesn not offer a native PHP solution so that's not an option.   

Fargate with ECS looks like it will give me what I need.   So let's dig into that. 

---

After some research  I've decided on building on what should be the final architecture.

In AWS:
- nginx container
- php-fpm container
- dynamodb cache
- aurora serverless mysql

Testing:
- nginx container
- php-fpm container
- redis
- mysql5.7

##  Prerequisites
The list of required items is fairly short. That's the benefit of working with docker. You get to build up a system by adding tasks to containers.  

### PHP7.4
You are on your own here.

### Composer
Use this link to see how.

https://getcomposer.org/download/




### Docker
Docker Desktop is an easy way to get docker going on your Mac or Windows system.

It has the included advantage of including Kubernetes all packaged up with a nice gui.

https://www.docker.com/products/docker-desktop

### Amazon Account
You will need an Amazon Web Services account for this to work in a production environment.

All amazon settings will be managed from the command line.  So setup you account for command line access.

You can follow along using the developement steps only.  This way you will have a working dockerized Laravel application.

---

# Getting Started

## Working Environment
I don't know what you have installed on your system and I dont really care.  So long as you have docker desktop we are the same you and I.  You can be working an a linux system running PHP5.6 and I can be on a windows system running IIS.  Docker is the great equalizer.

Open your console and check to see if docker is installed.  Version can be close enough. 

```bash
$ docker --version
Docker version 19.03.13, build 4484c46d9d
```
Sping up a new laravel project.  Inside your project made a folder and name in infra. This is where we are going to write the infrastructure code. 

```bash
$ composer 
Docker version 19.03.13, build 4484c46d9d
```

- create a build container
  - php7.4
  - composer
  - node





## NGINX container

NGINX is easy enough to setup on your linux system of choice.  You would use your package manager to install it then start it up, point the config file to your code and let it run forever.

That's just about the same thing in docker.

```docker
FROM nginx:1.18

# Install curl for health check
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y curl

# Configure NGINX
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy static files
COPY docker/nginx/index.html /var/www/html/
RUN chown -R nginx:nginx /var/www/html

HEALTHCHECK --interval=15s --timeout=10s --start-period=60s --retries=2 CMD curl -f http://127.0.0.1/health-check.php || exit 1

# Build
# docker build -t apitraffic-nginx:latest -f docker/nginx/Dockerfile .
```

