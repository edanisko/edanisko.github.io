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
How cold are aurora serverless cold starts?

I have an api with written in PHP that I need to stand up.

It gets spikey traffic throughout the day.  But when traffic comes it needs to respond quickly.

<!--more-->

Originally the system had an ALB, with 2 small instances serving the website and processing SQS.

the back end was Aurora mysql with Elasticache for sessions.

It was sort of expensive so I need to do a little remodeling to take advantage of some of the new, serverless products that are out there now.  I want to be able to pay for processing and stop paying for idle systems.

Laravel offers Vapor.  But that solution is a bit of a black box, and its kind of expensive too. So I am going to acknowledge it, then move on.  

Lambda doesn not offer a native PHP solution so that's not an option.   

Fargate with ECS looks like it will give me what I need.   So let's dig into that. 

I'll want this to be scripted all the way thorough.




