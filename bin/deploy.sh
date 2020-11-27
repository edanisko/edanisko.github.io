#!/usr/bin/env bash
rm -rf /docs && HUGO_ENV=production hugo -d docs --minify
git add .
git commit -m'deploy'
git push origin master
