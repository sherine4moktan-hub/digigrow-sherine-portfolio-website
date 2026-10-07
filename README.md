# Digigrow Sherine portfolio website

A fast, dependency-free static website for Sherine Moktan's AI-powered digital marketing services.

## Preview locally

```powershell
npm run dev
```

Then open `http://localhost:4173`.

## Edit the site

- Brand, booking URL, social links, services, and blog card content: `dist/assets/site-data.js`
- Global layout and interaction logic: `dist/assets/app.js`
- Visual design and responsive styles: `dist/assets/styles.css`
- Page copy: the matching `index.html` file under `dist/`
- Blog article copy: each article folder under `dist/blog/`

## Add Sherine's photo

Add an optimized WebP or AVIF portrait to `dist/assets/`, then replace the branded visual in the home and About page markup with an `<img>` element. Include accurate alternative text and set width/height attributes.

## Connect booking and the contact form

In `dist/assets/site-data.js`:

- Set `bookingUrl` to the real scheduling URL. Every “Book a Free Consultation Call” button will use it automatically.
- Set `formEndpoint` to a secure form handler that accepts JSON. Until it is configured, the contact form explicitly reports that it cannot send; it never displays a false success state.
- Add verified contact details and social URLs only when they are available.

Do not place secrets in browser JavaScript. Configure credentials in the selected form provider or server-side environment.

## Validate

```powershell
npm run check
```

The validator checks required routes, internal links, article slugs, CTA coverage, metadata, and key accessibility hooks.
