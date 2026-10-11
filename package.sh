#!/usr/bin/env bash
set -euo pipefail

comp="${1:-}"
case "$comp" in
  core)  mod="modDynamicScabbards"; zipname="DynamicScabbards.zip" ;;
  *) echo "usage: ./package.sh core" >&2; exit 2 ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root"

ver="$(sed -nE 's/^version = "([^"]+)".*/\1/p' "mods/$mod/witcherscript.toml")"
[ -n "$ver" ] || { echo "no 'version' in mods/$mod/witcherscript.toml" >&2; exit 1; }

mkdir -p dist
rel="dist/$zipname"
rm -f "$rel"
zip -qr "$rel" "mods/$mod" bin

echo "Built $rel (v$ver)"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  { echo "version=$ver"; echo "zip=$rel"; } >> "$GITHUB_OUTPUT"
fi
