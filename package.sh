#!/usr/bin/env bash
set -euo pipefail

comp="${1:-}"
case "$comp" in
  core)  mod="modDynamicScabbards";   with_bin=1; zipname="DynamicScabbards.zip" ;;
  soh)   mod="mod0_DS_SOH_Patch";     with_bin=0; zipname="DynamicScabbardsSwordsOnHipPatch.zip" ;;
  ahw)   mod="mod0_DS_AHW_Patch";     with_bin=0; zipname="DynamicScabbardsAutoHideWeaponsForCloaks.zip" ;;
  wpiao) mod="mod0_DS_WPIAO_Patch";   with_bin=0; zipname="DynamicScabbardsWearPreviewItemsAsOutfitsPatch.zip" ;;
  *) echo "usage: ./package.sh <core|soh|ahw|wpiao>" >&2; exit 2 ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root"

ver="$(sed -nE 's/^version = "([^"]+)".*/\1/p' "mods/$mod/witcherscript.toml")"
[ -n "$ver" ] || { echo "no 'version' in mods/$mod/witcherscript.toml" >&2; exit 1; }

mkdir -p dist
rel="dist/$zipname"
rm -f "$rel"
if [ "$with_bin" = 1 ]; then
  zip -qr "$rel" "mods/$mod" bin
else
  zip -qr "$rel" "mods/$mod"
fi

echo "Built $rel (v$ver)"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  { echo "version=$ver"; echo "zip=$rel"; } >> "$GITHUB_OUTPUT"
fi
