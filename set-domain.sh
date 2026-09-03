#!/bin/bash
# Point canonicals, OG tags, JSON-LD and the sitemap at a domain.
# Re-runnable: reads the domain currently in use and swaps it for the new one.
#   ./set-domain.sh boost.builtbyaero.com
cd "$(dirname "$0")"
NEW="${1#https://}"; NEW="${NEW#http://}"; NEW="${NEW%/}"
[ -z "$NEW" ] && { echo "usage: ./set-domain.sh yourdomain.com"; exit 1; }

CUR=$(grep -o 'rel="canonical" href="https://[^/"]*' index.html | head -1 | sed 's#.*https://##')
[ -z "$CUR" ] && { echo "Could not read the current domain from index.html"; exit 1; }
[ "$CUR" = "$NEW" ] && { echo "Already set to $NEW — nothing to do."; exit 0; }

FILES=$(grep -rl "$CUR" --include="*.html" --include="*.xml" --include="*.txt" . 2>/dev/null)
echo "$FILES" | xargs /usr/bin/sed -i '' "s#${CUR}#${NEW}#g"

echo "Domain: ${CUR}  ->  ${NEW}"
echo "Files updated: $(echo "$FILES" | wc -l | tr -d ' ')"
LEFT=$(grep -rc "$CUR" --include="*.html" --include="*.xml" --include="*.txt" . 2>/dev/null | grep -v ':0$')
[ -z "$LEFT" ] && echo "No references to the old domain remain." || { echo "WARNING, still present:"; echo "$LEFT"; }
