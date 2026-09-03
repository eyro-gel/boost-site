# BOOST — website

Static site: three HTML pages, one stylesheet, one script, images and video.
No build step — what is in this repo is what gets served.

```
index.html        homepage
packages.html     one-off packages (9)
plans.html        monthly management plans (9)
assets/           boost.css · boost.js · nojs.css · logos · img/ · video/
_headers          security headers (Cloudflare Pages / Netlify)
robots.txt        currently Disallow — the site is in staging mode
sitemap.xml
```

## Deploying

Point Cloudflare Pages (or Netlify) at this repo. Build command: none.
Output directory: `/`.

## Two scripts you will need

```bash
./set-domain.sh boost-tourism.co   # rewrites canonicals, OG tags, sitemap
./staging.sh off                   # re-enables indexing (final domain only)
```

The site is currently in **staging mode** — `noindex` on every page, a
`Disallow: /` robots.txt and an `X-Robots-Tag` header. Leave that on while it
lives on a review domain, or the review copy gets indexed and competes with the
real site later.

See `DEPLOY.md` for the full checklist, security notes and SEO state.
