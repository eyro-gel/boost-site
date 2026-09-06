#!/bin/bash
# Toggle search-engine visibility.
#   ./staging.sh on    -> noindex everywhere (use while it lives on a review domain)
#   ./staging.sh off   -> indexable (only once it is on the final BOOST domain)
cd "$(dirname "$0")"
MODE="$1"

LIVE='<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1">'
HIDE='<meta name="robots" content="noindex, nofollow">'

# every page, not just the root one — packages/ and plans/ live in their own
# directories now that the URLs are clean, and a root-only glob silently left
# them noindex at launch
pages() { find . -name '*.html' -not -path './.git/*'; }

case "$MODE" in
  on)
    pages | while read -r f; do /usr/bin/sed -i '' "s|$LIVE|$HIDE|" "$f"; done
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
    pages | while read -r f; do /usr/bin/sed -i '' "s|$HIDE|$LIVE|" "$f"; done
    DOMAIN=$(grep -o 'rel="canonical" href="https://[^/"]*' index.html | head -1 | sed 's#.*https://##')
    printf 'User-agent: *\nAllow: /\n\nSitemap: https://%s/sitemap.xml\n' "$DOMAIN" > robots.txt
    /usr/bin/sed -i '' '/^  X-Robots-Tag: noindex, nofollow$/d' _headers
    echo "STAGING MODE OFF — the site is indexable."
    echo "Remember: run ./set-domain.sh <final-domain> before or straight after this."
    ;;
  *)
    echo "usage: ./staging.sh on|off"
    if pages | xargs grep -l 'noindex' >/dev/null 2>&1; then
      echo "current: STAGING (noindex)"
    else
      echo "current: LIVE (indexable)"
    fi
    exit 1
    ;;
esac
echo "pages carrying noindex:"
pages | xargs grep -c 'noindex' | sed 's/^/  /'
