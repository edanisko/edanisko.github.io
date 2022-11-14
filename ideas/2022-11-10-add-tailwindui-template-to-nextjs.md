---

### What am I building?

This is a good question.  I am building ninespin.com.  It's a Godaddy killer.  I have for other killers that I'd like to build too.  So I know that in each case I will need all the basic website boilerplate.  Lander, Login, Admin, Terms, Pricing and a way to pay.  Instead of writing all of that myself I am going to use Tailwind UI.  By the way, I'm using the paid version there.  All access is not cheap.  But this is my career and I've never lost anything when paying for technology.  Even when it's only value was to learn a lesson on spotting scams.  TailwindUI full version is not a scam.  It's great.  And it helps the TailwindCSS guys out so I'm into it.  

https://tailwindui.com/components/marketing/page-examples/landing-pages

I'm going to use the 'A Better Way To Ship Apps' template.

- todo image

I copied the react code into a file and saved it.  Picking it apart I see there are some changes that need to be made to the tailwind.config.js file.  Those changes are going to need several new pacakges.  So let's install them.


```bash
pnpm install -D @tailwindcss/forms --save-dev
pnpm install -D @tailwindcss/aspect-ratio --save-dev
pnpm install -D @heroicons/react --save-dev
pnpm install -D @headlessui/react 
```

```javascript
/** @type {import('tailwindcss').Config} */
const colors = require('tailwindcss/colors')
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        teal: colors.teal,
        cyan: colors.cyan,
      },
    },
  },
  plugins: [
    // ...
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
  ],
}

```
add this to tsconfig.json

```json
    "baseUrl": ".",
    "paths": {
      "@/*": ["/*"]
    },
```

Its nice to have ui components in their own folder.  So let's make one.

Need a place to mock data for now too.  So let's make a folder for that.

```bash
mkdir app/components/ui
mkdir app/components/mockdata
```

The template is broken into three main parts: Popover, main, and footer.

Create those files in the ui folder then copy the code from the template into them.







---
