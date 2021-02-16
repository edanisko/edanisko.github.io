---
title: 'Laravel Development in Docker'
date: 2020-11-26T00:00:00-08:00
author: Ed Anisko
layout: post
categories:
  - Docker
  - Development
  - Laravel
  - Jetstream
  - PHP
---
There's a lot of PHP code out there.  Wordpress, Drupal, Zend, Laravel.  These are just a few of the untold endless frameworks.  Even so, PHP has conspicuously been left out of the buzzword rich, serverless revolution.  Today's PHP developer might be asking, am I the last. A remaining holdout of a simpler, more complicated time.  Maybe.  Surely the last ALGOL developer questioned the end, before it came.

Still there is a lot more PHP code out there than ALGOL, I'm guessing.  PHP code has to go somewhere.  Cramming it into a Lambda function is too messy.  There's always Docker.  Docker is pretty great.  But up until recently, Docker, in production, meant managing a cluster.  Managing a docker cluster is not great.   AWS Fargate ECS removes the cluster pain and makes Docker, serverless.

Follow along to create a Laravel Jetstream installation working locally inside a Docker container.  Later you can push the image to ECS, then get up and running in Fargate.

#### Requirements:
- Docker [install](https://docs.docker.com/desktop/)
- NodeJS [install](https://nodejs.com)
- AWS Account [here](https://aws.amazon.com/)



#### Roadmap

- Create a Laravel docker container
- Create a Laravel project in docker
<!-- - Create a production ready image (coming soon)
- Release to Fargate ECS (coming soon) -->



### Create a Laravel Docker Container

First check if docker is installed properly.
```
docker run hello-world
```
Docker will download something and you should see a Hello from Docker! message in the terminal.


Create a new directory for your project and move into it.
```sh
cd ~/ && mkdir phplaravel && cd phplaravel
```
For instance, this command will create a directory in the home folder for the logged in account and name it phplaravel.  Create an infrastructure directory within to keep infra code separated from app code.  Call the directory infra for short. 

Inside the infra directory create a file named Dockerfile. The tree stucture so far looks like this. 

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

Easier than you think, right? The Dockerfile will start off using the latest composer container provided in the docker containter repository.  Next it installs a few packages that Laravel will need to run.  



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













### Create a Laravel Project in Docker

The image is capable of running a dev version of Laravel.  This is a pared down, no frills version of Laravel but it works.  It leans on Laravel's brilliant use of adapters to maintain <a href="https://12factor.net/dev-prod-parity" target="_blank">dev - prod parity</a>.

Follow along to create a Laravel project on the host disk drive, that can be edited and run inside the container.


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

On the host machine there will be a new directory named **laravel**.  Make changes with your editor in this directory and those changes will be present inside the docker container.  This is a working dev version of Laravel Jetstream.  

```sh
phplaravel
└── infra
|    └── Dockerfile
└── laravel    
     └── app
     └── bootstrap
     └── ...          
 ```


The app still needs a database.  Keep things simple and add one change the .env file and create a sqlite database following the instructions below.  First open the project in an editor.

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

Back in the terminal insode of the docker instance migrate the database.  Then, serve the project.
```
php artisan migrate

php artisan serve --port 8888 --host 0.0.0.0
```

Open your browser and play around with you local docker dev version of Jetstream. <a href="http://localhost:8888" target="_blank">http://localhost:8888</a>

Configure Jetstream according to their docs. <a href="https://jetstream.laravel.com/" target="_blank">Jetstream</a>

Pretty good right?

CTRL-C to turn off your server or open another terminal to continue working inside docker. All composer packages and npm packages should be added inside the container.

This command connects back to the docker container from the terminal.

```
docker exec -it phplaravel-container bash
```

---







