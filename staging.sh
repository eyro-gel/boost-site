#!/bin/bash
# Toggle search-engine visibility.
#   ./staging.sh on    -> noindex everywhere (use while it lives on a review domain)
#   ./staging.sh off   -> indexable (only once it is on the final BOOST domain)
cd "$(dirname "$0")"
MODE="$1"

LIVE='<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1">'
HIDE='<meta name="robots" content="noindex, nofollow">'

case "$MODE" in
  on)
    for f in *.html; do
      /usr/bin/sed -i '' "s|$LIVE|$HIDE|" "$f"
    done
    cat > robots.txt <<'ROB'
# Review deployment — not the live site. Do not index.
User-agent: *
Disallow: /
ROB
    /usr/bin/sed -i '' 's|^  Content-Security-Policy|  X-Robots-Tag: noindex, nofollow\
  Content-Security-Policy|' _headers
    echo "STAGING MODE ON — noindex meta, robots.txt disallow, X-Robots-Tag header."
    echo "Search engines will stay out. Turn this off only on the final domain."
    ;;
  off)
    for f in *.html; do
      /usr/bin/sed -i '' "s|$HIDE|$LIVE|" "$f"
    done
    DOMAIN=$(grep -o 'rel="canonical" href="https://[^/"]*' index.html | head -1 | sed 's#.*https://##')
    printf 'User-agent: *\nAllow: /\n\nSitemap: https://%s/sitemap.xml\n' "$DOMAIN" > robots.txt
    /usr/bin/sed -i '' '/^  X-Robots-Tag: noindex, nofollow$/d' _headers
    echo "STAGING MODE OFF — the site is indexable."
    echo "Remember: run ./set-domain.sh <final-domain> before or straight after this."
    ;;
  *)
    echo "usage: ./staging.sh on|off"
    grep -l 'noindex' *.html >/dev/null 2>&1 && echo "current: STAGING (noindex)" || echo "current: LIVE (indexable)"
    exit 1
    ;;
esac
grep -c 'noindex' *.html | sed 's/^/  /'
