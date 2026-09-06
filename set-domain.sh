#!/bin/bash
# Point canonicals, OG tags, JSON-LD, the sitemap, robots.txt and CNAME at a domain.
# Re-runnable: reads the domain currently in use and swaps it for the new one.
#   ./set-domain.sh boost-tourism.co
cd "$(dirname "$0")"
NEW="${1#https://}"; NEW="${NEW#http://}"; NEW="${NEW%/}"
[ -z "$NEW" ] && { echo "usage: ./set-domain.sh yourdomain.com"; exit 1; }

CUR=$(grep -o 'rel="canonical" href="https://[^/"]*' index.html | head -1 | sed 's#.*https://##')
[ -z "$CUR" ] && { echo "Could not read the current domain from index.html"; exit 1; }
[ "$CUR" = "$NEW" ] && { echo "Already set to $NEW — nothing to do."; exit 0; }

# Only ever rewrite "https://<domain>", never the bare domain on its own.
# A bare swap also hits things that merely contain the domain — the contact
# address support@boost-tourism.co being the one that bites.
FILES=$(grep -rl "https://${CUR}" --include="*.html" --include="*.xml" --include="*.txt" . 2>/dev/null)
[ -n "$FILES" ] && echo "$FILES" | xargs /usr/bin/sed -i '' "s#https://${CUR}#https://${NEW}#g"

# CNAME holds the bare domain and is the whole file, so it is set, not patched
[ -f CNAME ] && echo "$NEW" > CNAME

echo "Domain: ${CUR}  ->  ${NEW}"
echo "Files updated: $(echo "$FILES" | grep -c . )$([ -f CNAME ] && echo ' (+ CNAME)')"
LEFT=$(grep -rc "https://${CUR}" --include="*.html" --include="*.xml" --include="*.txt" . 2>/dev/null | grep -v ':0$')
[ -z "$LEFT" ] && echo "No references to the old domain remain." || { echo "WARNING, still present:"; echo "$LEFT"; }
