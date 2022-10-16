---
title: "Shortcuts"
date: 2020-10-12T12:55:37-07:00
draft: false
---

This page is for links and snippets that I use regularly enough that I need a place for them.  

## Hugo Build Command
```bash
$ rm -rf /docs && HUGO_ENV=production hugo -d docs --minify
```

## AWS SSO Login

https://edanisko.awsapps.com/login/

## Docker

```
docker rm phplaravel-container -f

docker build -t phplaravel:latest -f Dockerfile .

docker run --name phplaravel-container  -t -d phplaravel

docker exec -it phplaravel-container bash 
```

