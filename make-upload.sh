#!/bin/bash
# Build the folder to hand Cloudflare Pages (Direct Upload).
#
# Only site files go in. The repo also holds tooling and notes — DEPLOY.md,
# README.md, the two .sh scripts — and a plain drag-and-drop of the repo folder
# publishes all of it as downloadable files. That is what happened on GitHub
# Pages, where /set-domain.sh and /DEPLOY.md are still fetchable.
#
#   ./make-upload.sh            -> _upload/ and boost-site-upload.zip
set -e
cd "$(dirname "$0")"

OUT="_upload"
ZIP="boost-site-upload.zip"

rm -rf "$OUT" "$ZIP"
mkdir -p "$OUT"

# everything the served site needs, and nothing else
cp -R assets "$OUT"/
cp index.html 404.html favicon.ico robots.txt sitemap.xml _headers _redirects "$OUT"/
mkdir -p "$OUT/packages" "$OUT/plans"
cp packages/index.html "$OUT/packages"/
cp plans/index.html "$OUT/plans"/

# strip anything macOS or the editor left behind
find "$OUT" \( -name '.DS_Store' -o -name '._*' -o -name '*.swp' \) -delete

# a zip is easier to upload than a deep folder, and Pages accepts either.
# -x excludes the resource forks macOS adds to archives.
( cd "$OUT" && zip -qr "../$ZIP" . -x '.*' -x '__MACOSX/*' )

FILES=$(find "$OUT" -type f | wc -l | tr -d ' ')
BYTES=$(find "$OUT" -type f -exec stat -f%z {} + | awk '{s+=$1} END {print s}')
BIG=$(find "$OUT" -type f -size +25000k | head -1)

echo "Built $OUT/ and $ZIP"
echo "  files: $FILES   (Pages allows 20,000)"
printf "  size : %.1f MiB\n" "$(echo "$BYTES/1048576" | bc -l)"
if [ -n "$BIG" ]; then
  echo "  WARNING: over the 25 MiB per-file limit: $BIG"
else
  echo "  largest file is within the 25 MiB per-file limit"
fi
echo
echo "Excluded on purpose: README.md, DEPLOY.md, set-domain.sh, staging.sh,"
echo "make-upload.sh, CNAME, .git — none of them belong on a public site."
