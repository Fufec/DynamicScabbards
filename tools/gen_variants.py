#!/usr/bin/env python3
"""Generates bundle_src/gameplay/items{,_plus}/dynamic_scabbards.xml from tools/scabbards.toml.

Every listed scabbard definition gets an item_extension with one variant per witcher school:
while the invisible marker item of that school is mounted, the engine spawns the sword's bound
scabbard from the school template instead of its own. Pack with tools/pack_bundle.sh afterwards.
"""
import tomllib
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# templates of the vanilla school scabbards, see GetSteelMarker/GetSilverMarker in DynamicScabbards.ws
SCHOOLS = {
    'kaermorhen': dict(steel='scabbard_steel_1_01',              silver='scabbard_silver_1_01'),
    'bear':       dict(steel='witcher_steel_bear_scabbard',      silver='witcher_silver_bear_scabbard'),
    'lynx':       dict(steel='witcher_steel_lynx_scabbard',      silver='witcher_silver_lynx_scabbard'),
    'gryphon':    dict(steel='witcher_steel_gryphon_scabbard',   silver='witcher_silver_gryphon_scabbard'),
    'wolf':       dict(steel='witcher_steel_wolf_scabbard',      silver='witcher_silver_wolf_scabbard'),      # dlc10
    'manticore':  dict(steel='witcher_steel_wolf_scabbard_ep2',  silver='witcher_silver_wolf_scabbard_ep2'),  # Blood and Wine, Red Wolf School
    'viper':      dict(steel='scabbard_steel_1_02',              silver='scabbard_silver_1_05'),
    'netflix':    dict(steel='witcher_steel_netflix_scabbard',   silver='witcher_silver_netflix_scabbard'),
}
KINDS = {'steel_scabbards': 'steel', 'silver_scabbards': 'silver'}  # scabbard category -> marker kind

scabbards = tomllib.loads((ROOT / 'tools' / 'scabbards.toml').read_text('utf-8'))

root = ET.Element('redxml')
definitions = ET.SubElement(root, 'definitions')

items = ET.SubElement(definitions, 'items')
items.append(ET.Comment(' invisible markers: the mounted one tells the engine which school scabbard to spawn '))
for kind in KINDS.values():
    for school in SCHOOLS:
        item = ET.SubElement(items, 'item', name=f'ds_{kind}_{school}', category=f'ds_{kind}',
                             equip_template='', attachment_type='skinning')
        ET.SubElement(item, 'tags').text = 'NoShow,NoDrop,EncumbranceOff'

extensions = ET.SubElement(definitions, 'items_extensions')
for category, names in scabbards.items():
    kind = KINDS[category]
    for name in names:
        variants = ET.SubElement(ET.SubElement(extensions, 'item_extension', name=name), 'variants')
        for school, templates in SCHOOLS.items():
            variant = ET.SubElement(variants, 'variant', equip_template=templates[kind])
            ET.SubElement(variant, 'item').text = f'ds_{kind}_{school}'

ET.indent(root, '\t')
xml = '<?xml version="1.0" encoding="UTF-16"?>\n' + ET.tostring(root, encoding='unicode') + '\n'
for folder in ('items', 'items_plus'):
    out = ROOT / 'bundle_src' / 'gameplay' / folder / 'dynamic_scabbards.xml'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(xml.replace('\n', '\r\n').encode('utf-16'))  # BOM and CRLF like the vanilla item XML

print(f'{sum(map(len, scabbards.values()))} scabbards, {len(SCHOOLS)} schools -> bundle_src/')
