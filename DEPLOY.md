# Deploying BOOST — security checklist

This is a **static site**: three HTML files, one stylesheet, one script, images and
video. No database, no server-side code, no login, no user accounts. That removes
most of what usually goes wrong — SQL injection, session hijacking, and
server-side execution are all impossible here. The real risks are narrower, and
they're listed below in the order they'll actually bite you.

---

## 1. The contact form is the whole attack surface

Right now `action="#"` — it does nothing. When you wire it up:

- **Never build your own PHP mail handler.** Use a hosted form endpoint
  (Formspree, Basin, Cloudflare Pages Functions, Netlify Forms). They handle spam
  and validation and there's no code of yours to exploit.
- **Add a honeypot field** (a hidden input real people leave empty) — stops most
  bots for free.
- **Add Cloudflare Turnstile** rather than reCAPTCHA. Same job, no data sent to Google.
- **Never render submitted text as HTML** in the notification email. If someone
  submits `<script>` and your inbox renders it, that's on the handler.
- **Update the CSP** in `_headers` — `form-action 'self'` must change to include
  your endpoint's origin or the submission will be blocked.

## 2. Headers — already written

`_headers` in this folder works as-is on **Cloudflare Pages** and **Netlify**.
It sets a strict Content-Security-Policy, HSTS, `nosniff`, a referrer policy, a
permissions policy, and clickjacking protection.

The CSP is genuinely strict — `script-src 'self'` with no `unsafe-inline` — because
I removed the last 17 inline `style=` attributes and moved them to utility classes.
Keep it that way: the moment you paste in an analytics snippet or a chat widget,
that CSP will block it, and the fix is to add that origin explicitly, **not** to add
`'unsafe-inline'`.

On other hosts translate the same headers into `.htaccess` (Apache) or a
`add_header` block (nginx). Test the result at **securityheaders.com** — you should
score A or A+.

## 3. Pick a host that has no server for you to patch

Best options, all with free HTTPS, a CDN and DDoS absorption:

- **Cloudflare Pages** — good presence in Asia, closest to your customers
- **Netlify** or **Vercel** — equally fine

Avoid a VPS or WordPress unless you have a reason. Every one of those is a
patching obligation you'd be taking on for a site that doesn't need it.

## 4. Move the video off your own hosting

`assets/video/` is ~99MB. Self-hosted video has no adaptive bitrate, and on a
metered host a few hundred plays is a real bill — which also makes it a cheap way
for someone to run up your costs. Put the three presenter videos on YouTube or
Vimeo (unlisted if you prefer) and embed them. Add the embed origin to the CSP's
`frame-src` when you do.

## 5. Thailand PDPA — the obligation people forget

The form collects name, email, business name and website. Under the PDPA you need:

- A **privacy notice** explaining what you collect, why, how long you keep it, and
  who else sees it. **The site has no privacy policy page yet — this needs writing
  before launch.**
- A lawful basis for processing, and a route for people to request deletion.
- Care with anything that sends visitor data abroad.

Related: the fonts still load from `fonts.googleapis.com`, which sends every
visitor's IP to Google. Self-hosting the two font families removes that entirely
and tightens the CSP to `'self'` — worth doing, and it's a small job.

## Publishing to a review domain first

The site is currently in **staging mode** — `noindex` on every page, a
`Disallow: /` robots.txt, and an `X-Robots-Tag: noindex` response header. Three
layers, because any one of them can be missed.

**Why this matters more than it sounds.** If an indexable copy goes up on a
review domain, Google will index it before the real site exists. When BOOST's
own domain launches, the search engine already has the same content on another
host — the review copy can end up treated as the original and the real site as
the duplicate. That is a self-inflicted problem that takes months to unwind, and
it would be a poor look for an agency that sells search visibility.

### While it lives on the review domain

```
./staging.sh on        # already applied
```

Leave it on. Optionally also gate the site behind Cloudflare Access so nobody
stumbles across it at all. Do **not** submit the sitemap to Search Console yet.

### When it moves to the BOOST domain

```
./set-domain.sh boost-tourism.co     # rewrites canonicals, OG tags, sitemap
./staging.sh off                     # re-enables indexing
```

Then, in order:

1. Verify the domain in Google Search Console and submit `sitemap.xml`.
2. If the review copy stays up, **301 it to the live domain** — or take it down.
   Leaving two live copies is the duplicate-content problem all over again.
3. Run the URL Inspection tool on all three pages to confirm they are indexable.
4. Check the Rich Results Test for the structured data.

## SEO — what is done, and what still needs you

### Already in place

- **Unique title and meta description per page**, keyword-bearing and within
  Google's display limits (titles 51–56 chars, descriptions 163–174).
- **Canonical URLs** on all three pages — prevents the same page ranking twice
  from `/`, `/index.html`, `?focus=web` and so on. This matters here because the
  Focus switcher writes a query string into the URL.
- **Open Graph and Twitter cards** with a 1200×630 share image
  (`assets/img/og-cover.jpg`), so links posted to Facebook, LinkedIn or WhatsApp
  render as a proper card instead of a bare URL.
- **Structured data (JSON-LD)**:
  - `ProfessionalService` — name, area served across eight countries, services,
    founder and team. This is the one that feeds local/entity understanding.
  - `WebSite`, `BreadcrumbList` on the two subpages, `Service` + `OfferCatalog`
    describing the three families × three levels.
  - `FAQPage` generated **from the page's own FAQ text**, so the markup cannot
    drift out of sync with the copy.
- **`sitemap.xml`** and a `robots.txt` that points at it.
- One `<h1>` per page, clean `h2`/`h3` hierarchy, and alt text on every
  content image (decorative ones correctly left empty).

### Set the domain first

Everything above uses `YOURDOMAIN.com` as a placeholder. One command:

```
./set-domain.sh boosttourism.com
```

It rewrites the HTML, sitemap and robots, then reports any placeholder it missed.

### What still needs doing

1. ~~Fix the video weight~~ — done. Re-encoded from the 4K masters to 720p at
   ~1.7 Mbps: the folder went from 98MB to 23MB, and every file is now well under
   Cloudflare Pages' 25 MiB per-file limit. All four are `faststart`, so they
   begin playing before they finish downloading, and the three presenter videos
   are still `preload="none"` behind a poster — nothing downloads until someone
   presses play. YouTube or Vimeo would still be better if you want adaptive
   bitrate for weak mobile connections, but self-hosting is now viable.
2. ~~Real contact details~~ — done. The `ProfessionalService` block now carries
   support@boost-tourism.co, +66 88 924 7878, both social profiles and a
   `ReserveAction` pointing at the Calendly booking.
3. **Create the Google Business Profile** and add its URL to the `sameAs` array
   in the JSON-LD on `index.html`, alongside the Facebook and Instagram profiles
   already listed. That is what links the website entity to the business entity.
4. **Self-host the fonts.** Removes a third-party round trip on first paint and
   the PDPA exposure noted above.
5. **Verify in Google Search Console** once live, submit the sitemap, and check
   the Rich Results Test for the structured data.
6. **Publish something.** Three pages will rank for your brand name and little
   else. The old design had an Insights section for a reason — a handful of
   genuinely useful articles targeting the searches your prospects make
   ("how to fix my Google listing Thailand") is what earns non-brand traffic.

### One honest caveat

`FAQPage` markup no longer produces rich results for most sites — since 2023
Google shows FAQ rich snippets almost exclusively for government and health
domains. It is still worth having for entity understanding, but do not expect
expanding questions in the search results.

## 6. Lock the accounts, not just the site

This is how small businesses actually get compromised — nobody exploits the HTML,
they take over an account.

- **2FA on the registrar, the DNS, the host and the email** — all four.
- **Registrar lock** enabled on the domain.
- **SPF, DKIM and DMARC** records if you send mail from the domain. Without them,
  anyone can spoof `hello@yourdomain` — a real risk when you're emailing prospects
  cold and asking them to trust you.
- Deploy from a **git repository** so every change is reviewable and revertible.

## 7. On protecting the design once it's live

A deployed website is public by definition. Anyone can read the HTML and CSS and
copy the layout, and no technical measure changes that — right-click blockers and
JavaScript obfuscation are theatre. What protects the work is the signed proposal,
the dated paper trail, and not publishing until you've been paid. The watermarked
review PDF is the right tool for the pre-approval stage; a live site is not.

---

## Pre-launch checklist

- [x] Trial booking wired to Calendly
- [ ] Enquiry form wired to a real endpoint, honeypot and Turnstile added, CSP updated
- [ ] Privacy policy page written and linked in the footer
- [x] Real contact details — support@boost-tourism.co / +66 88 924 7878
- [ ] 18 prices filled into the `data-price` attributes
- [ ] Founder name in the About section
- [x] Social links live (Facebook + Instagram; LinkedIn removed)
- [x] Videos re-encoded to ~1.7 Mbps (284MB of source → 23MB shipped)
- [ ] Fonts self-hosted
- [ ] Sitemap generated and referenced in `robots.txt`
- [ ] securityheaders.com score checked
- [ ] 2FA on registrar, DNS, host, email
