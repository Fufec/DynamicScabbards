#!/usr/bin/env bash
# Packs bundle_src/ into mods/modDynamicScabbards/content/blob0.bundle + metadata.store with wcc_lite
# (Script Merger\Tools\wcc_lite). Run from WSL; wcc_lite needs a Windows working directory.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wcc="${WCC_LITE:-/mnt/c/Program Files (x86)/Steam/steamapps/common/The Witcher 3/Script Merger/Tools/wcc_lite/bin/x64/wcc_lite.exe}"
[ -x "$wcc" ] || { echo "wcc_lite not found: $wcc (set WCC_LITE)" >&2; exit 1; }
src="$(wslpath -w "$root/bundle_src")"
out_dir="$root/mods/modDynamicScabbards/content"
out="$(wslpath -w "$out_dir")"
rm -f "$out_dir"/blob*.bundle "$out_dir/metadata.store"
cd "$(dirname "$wcc")"
./wcc_lite.exe pack -dir="$src" -outdir="$out" 2>&1 | tr -d '\r' | grep -E "Error|Warning|Packing|bundle" || true
./wcc_lite.exe metadatastore -path="$out" 2>&1 | tr -d '\r' | grep -E "Error|Warning|metadata" || true
ls -l "$out_dir"/blob*.bundle "$out_dir/metadata.store"
