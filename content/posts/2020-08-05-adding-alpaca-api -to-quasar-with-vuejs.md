---
title: 'Adding Alpaca API to Quasar with VueJS'
date: 2020-08-05T22:45:54-08:00
author: Ed Anisko
layout: post
aliases:
    - /posts/2020-08-05-quasar-queries/
categories:
  - Quasar
  - Node
  - Trading
tags:
  - api 
  - node 
  - trading
  - apps 
  - quasar    
---
Its easy enough to use the alpaca CLI in a flat js file.  Next step is to add it to an application, add a few buttons and make it do something. 


Objective: Add the Alpaca API to a Quasar VueJS project then buy a share of QQQ. 


<!--more-->


Read the code, specifically the comments in the .quasar folder.  They point to setting up a boot directive.   A link in the comments points to:
- https://quasar.dev/quasar-cli/boot-files#Anatomy-of-a-boot-file

Found this article about adding axios.
- https://medium.com/quasar-framework/adding-axios-to-quasar-dbe094863728


Go to your Quasar application folder.

Set up axios according to the post above.

The setup Alpaca API.

```sh
$ npm install --save @alpacahq/alpaca-trade-api    
$ quasar new boot axios

```

This creates /boot/alpaca-api.js
Add the following code to that file.  Change teh keys to your own Alpaca keys.

```js
const Alpaca = require('@alpacahq/alpaca-trade-api')

const alpacaInstance = new Alpaca({
  keyId: 'XXXXXXXXXXXXXXXXX',
  secretKey: 'XXXXXXXXXXXXXXXXXX',
  paper: true,
  usePolygon: false
})

export default async ({ Vue }) => {
  Vue.prototype.$alpaca = alpacaInstance
}

export { alpacaInstance }

```

in /quasar.conf.js add alpaca-api to the boot array:
```js
    // app boot file (/src/boot)
    // --> boot files are part of "main.js"
    // https://quasar.dev/quasar-cli/boot-files
    boot: [
      'alpaca-api',
      'axios'
    ],

```


Then change /src/App.vue
```js
<template>
  <div id="q-app">
    <router-view />
  </div>
</template>
<script>

import { alpacaInstance } from 'boot/alpaca-api'

export default {
  name: 'App',
  mounted () {
    console.log(alpacaInstance.getAccount())
  }
}
</script>
```

If done correcly, the log will show your account information.  Take a look at the other commands available in the Alpaca nods SDK.

https://github.com/alpacahq/alpaca-trade-api-js/

