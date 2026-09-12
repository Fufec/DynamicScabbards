#!/usr/bin/env python3
"""Packs bundle_src/ into mods/modDynamicScabbards/content/{blob0.bundle,metadata.store} with wcc_lite
(Script Merger). Windows only; wcc_lite must run from its own directory."""
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'mods' / 'modDynamicScabbards' / 'content'
WCC = Path(os.environ.get('WCC_LITE', r'C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3'
                                       r'\Script Merger\Tools\wcc_lite\bin\x64\wcc_lite.exe'))


def wcc(*args):
    log = subprocess.run([WCC, *args], cwd=WCC.parent, capture_output=True, text=True).stdout
    for line in log.splitlines():
        if 'Error' in line or 'Warning' in line:
            print(line)


for old in OUT.glob('blob*.bundle'):
    old.unlink()
(OUT / 'metadata.store').unlink(missing_ok=True)

wcc('pack', f'-dir={ROOT / "bundle_src"}', f'-outdir={OUT}')
wcc('metadatastore', f'-path={OUT}')

for name in ('blob0.bundle', 'metadata.store'):
    print(name, (OUT / name).stat().st_size, 'B')
