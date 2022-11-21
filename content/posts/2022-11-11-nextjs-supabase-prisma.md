---
title: NextJS - TailwindCSS - Supabase - Prisma
date: 2022-11-11T23:00:55-08:00
author: Ed Anisko
layout: post
aliases: null
featured_image: /img/nextjs.png
images:
  - /img/nextjs.png
description: NextJS - TailwindCSS - Supabase - Prisma
keywords:
  - NextJS
  - TailwindCSS
  - Supabase
  - Prisma
categories:
  - NextJS
  - SQL
tags:
  - NextJs
  - TailwindCSS
  - Supabase
  - Prisma
  - Vercel
  - SQL
lastmod: 2022-11-21T05:24:03.462Z
---

## A NextJS Site with a SQL Backend

It's raining JavaScript frameworks! There are as many frameworks as there are free places to host your Javascript Framework based site.  That only works for PHP if you're willing to build a wordpress site.  So before the rest of the free world decides to charge for their products like Heroku.  I'm jumping on the bandwagon.  I like NextJS.  I'm going to run with that and hook it up to a SQL backend.  I've had to do some database work lately and have bene reminded on how nice normalized data is to work with.  

So where can you get a free SQL database?  Supabase and CockroachDB.  Supabase is a more feature rich.  It has a friendly user interface.  You can view your data and query against it in the browser.  Supabase also has an Auth service, somthing like S3 storage and more.  

CockroachDB has less but is more... simple.  It gives you a server and a good selection of connection strings.  However the integration with the ORM is not as smooth.  I found myself having to change data types.  For example, Int to BigInt so that autoincrement works properly in the id field of a model.  

Prisma is the ORM that will glue this project together.  So eventhough I like the simplicity of CockroachDB, I'm going to use Supabase for this project.  

I'm going to add TailwindCSS into this too.  I'll be using their UI components to build out my side projects and this guide will serve as a starter for those projects.

Buckle up!!  Node J typescript here we come.  Mac people go install brew and maybe even the warp terminal.  Windows people go borrow a Mac.

## Install Requirments

First NodeJS.  It took at least five years to be able to install node and run npm without it blowing up.  It's stable now.  Except you're not suppose to use the odd numbered versions.  I install **NVM**. It's which is a node version manager like pyenv.  Install it with brew.  Then install Node with NVM.

The best of the NodeJS package managers at the moment is **pnpm**.  It's faster and more reliable than NPM.  Install it with brew. 

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install warp #(optional - but recommended)

brew instal nvm

nvm install 16

nvm use 16

brew install pnpm

```


## NextJS

Open up your terminal and change into your project directory.

I want to use the new features of NextJS 13.  At the time of this writing these features are part of the experimental features of the framework.  They are sanity saving timesavers.   

```bash
pnpm create next-app --experimental-app --ts my-app

cd my-app

pnpm dev
```

You will see a new browser window open with a NextJS app.  





## Supabase

Next you should get a GitHub account.  It's free.  Supabase will let you to sign in with your GitHub account.  Vercel, the parent company for NextJS will let you host apps for free with a GitHub login too. 

Click on create project.  If this is your first time you will have to setup an Organziation.  As soon as you give your organization a name you can name your project.

It take a moment to spin up.  When ready, copy your connection string.  Find it by clicking 'Project Settings', the gear icon.  Then 'database' from the sub menu.  At the bottom of the page is a Connection String panel.  Copy the connection string.  Createa a new file in the root of your project called .env.  Save the connection string in the .env file.  If you forgot your password like I did, you can reset that here too. 

```bash
DATABASE_URL="postgresql://postgres:[YOUR-PASSWORD]@db.ydzrfarzqidhroyvbvbq.supabase.co:5432/postgres"
```




## TailwindCSS

```bash
pnpm install -D tailwindcss postcss autoprefixer

pnpx tailwindcss init -p
```

This will create your **tailwind.config.js** and **postcss.config.js** files.  No change is needed in the postcss file.  You will edit the TailwindCSS config file, it should look like this.

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

Next delete whatever is in the **/app/global.css** file and relpace it.  You can add things later but for now I will only be adding the TailwindCSS base styles. 

```bash

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Find the file **/app/page.module.css**.  Delete the content.  You may start to see the NextJS patterns showing up.  This structured naming is the way NextJS wants you to do things.  It helps making sense of things.

Next open **/app/page.tsx**.  This is the home page.  Let's make it super simple.

```tsx
export default function Home() {
  return (
    <h1 className="text-3xl font-bold underline">
      Hello Next and Tailwind!
    </h1>
  )
}
```

Go back to the terminal and run the dev server again.

```bash
pnpm dev # imporant to restart the dev server
```

You will see the hello message styled with Tailwind classes.

___


## Prisma

Installing Prisma has a few tweaks too.  It's mostly straightforewrd.  

```bash
pnpm install typescript ts-node @types/node --save-dev

```

The package wants the sourceMap and outDir added to **tsconfig.json**.  The rest we already have.

```tsx
{
  "compilerOptions": {
    "sourceMap": true,
    "outDir": "dist"
  }
}
```

Next, install the packages.

```bash
pnpm install prisma --save-dev

pnpm prisma init --datasource-provider postgresql

pnpm install @prisma/client 

```

You will find the configuration files in a new folder and file in your project.  

Update the schema.prisma with a few models.  I took these examples directly from the Prisma site.

```tsx
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
  posts Post[]
}

model Post {
  id        Int     @id @default(autoincrement())
  title     String
  content   String?
  published Boolean @default(false)
  author    User    @relation(fields: [authorId], references: [id])
  authorId  Int
}

```

Now create those tables in the database.

```bash
pnpm prisma db push
``` 

Oh my stars!  It worked!  The schema file has been turned into SQL and the tables created on the database.

As a side note, I was also able to build an entire Laravel project using blueprint.  I migrated the database to Supabase and then used the pull command to create the schema files in JS.

```bash
pnpm prisma db pull
``` 

---

## Using the Database

To finish up, I'd like to add a few rows to the database and read them back through NextJS.

You can add rows directly into the Supabase console.  There is a local console that is very easy to use too.

```bash
pnpm prisma studio
```

Add a few users to the users table. Then get the users to show up on the home page.  The log: attribute is not required but it can be helpful to see what is going on.  It will show up in the terminal where you are running the dev server.

```typescript
import { PrismaClient } from "@prisma/client";

async function getData() {
  const prisma = new PrismaClient({ log: ['query', 'info'] })
  const res = await prisma.user.findMany()  
  return res;
}

export default async function Page() {
  const data = await getData();
  console.log(data)

  return (
    <>
      <ul className="text-3xl">
        {data.map((user) => (
          <li key={user.id}>{user.name} - {user.email}</li>
        ))}
      </ul>
    </>
  )
}
```

And there you have it.  I hope this helps you get started.  If there is anything I missed and you would like to add, comment below.  If you have any questions, please ask.  I'll do my best to answer.  I'm still learning too.  I'm sure there are better ways to do things.  I'm open to suggestions.  Thanks for reading.  Happy coding!