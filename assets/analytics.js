/* Google Analytics 4 — the configuration half of Google's gtag snippet.
   Google ships this as an inline <script>, which the site's CSP blocks:
   script-src is 'self' with no 'unsafe-inline', and adding 'unsafe-inline'
   to admit four lines of analytics would open the door to every injected
   script on the site. Served from the same origin instead, it needs no
   exception at all. The loader stays a normal external script and only
   googletagmanager.com is added to script-src.

   Load order does not matter: gtag.js drains whatever is already queued in
   dataLayer when it finishes loading. */
window.dataLayer = window.dataLayer || [];
function gtag() { dataLayer.push(arguments); }
gtag('js', new Date());
gtag('config', 'G-P61MXR28SM');
