#!/bin/sh
set -eu

SRC="/Users/gleb/Documents/Leonid/slovo-app/site-patch"
DST="/Users/gleb/Documents/GitHub/glebanya13/davinchi.dev"
TS=$(date +%Y%m%d-%H%M%S)

cp "$DST/apps/slovo/privacy.html" "/tmp/slovo-privacy-$TS.html"
cp "$DST/apps/christian-ai/privacy.html" "/tmp/christian-ai-privacy-$TS.html"
cp "$DST/apps/slovo/delete-account.html" "/tmp/slovo-delete-account-$TS.html" 2>/dev/null || true
cp "$SRC/apps/slovo/privacy.html" "$DST/apps/slovo/privacy.html"
cp "$SRC/apps/christian-ai/privacy.html" "$DST/apps/christian-ai/privacy.html"
cp "$SRC/apps/slovo/delete-account.html" "$DST/apps/slovo/delete-account.html"

cd "$DST"
echo "Updated files (previous versions saved in /tmp):"
echo "  /tmp/slovo-privacy-$TS.html"
echo "  /tmp/christian-ai-privacy-$TS.html"
echo
echo "Changed lines:"
diff -u "/tmp/slovo-privacy-$TS.html" apps/slovo/privacy.html | grep -c '^+' || true
diff -u "/tmp/christian-ai-privacy-$TS.html" apps/christian-ai/privacy.html | grep -c '^+' || true
if [ -f "/tmp/slovo-delete-account-$TS.html" ]; then diff -u "/tmp/slovo-delete-account-$TS.html" apps/slovo/delete-account.html | grep -c '^+' || true; else echo "new file: delete-account.html"; fi
echo
echo "Git status:"
git status --short -- apps/slovo/privacy.html apps/christian-ai/privacy.html apps/slovo/delete-account.html || true
echo
echo "Deploy with:"
echo "  cd \"$DST\" && npm run deploy"
