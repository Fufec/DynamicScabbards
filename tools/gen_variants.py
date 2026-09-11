#!/usr/bin/env python3
"""Generates the item definitions of Dynamic Scabbards (mod bundle XML).

Reads tools/scabbards.txt and writes
  bundle_src/gameplay/items/dynamic_scabbards.xml       (regular game)
  bundle_src/gameplay/items_plus/dynamic_scabbards.xml  (New Game+)
Both files are UTF-16 with BOM and CRLF, the same as the vanilla item XML.

The file defines 16 invisible items (one per school and sword category) and, for every
scabbard definition in the list, an item_extension with one variant per school: when the
invisible item of a school is mounted, the engine spawns the bound scabbard of the sword
from the school template instead of its own. Pack with tools/pack_bundle.sh afterwards.
"""
import os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIST = os.path.join(ROOT, 'tools', 'scabbards.txt')
OUT = [os.path.join(ROOT, 'bundle_src', 'gameplay', 'items', 'dynamic_scabbards.xml'),
       os.path.join(ROOT, 'bundle_src', 'gameplay', 'items_plus', 'dynamic_scabbards.xml')]

# school -> (steel template, silver template); the templates of the vanilla school scabbards
# scabbard_steel_1_01, scabbard_steel_bear_01, ... (see DynamicScabbards.ws GetSteelSchoolItemName)
SCHOOLS = [
    ('kaermorhen', 'scabbard_steel_1_01',            'scabbard_silver_1_01'),
    ('bear',       'witcher_steel_bear_scabbard',    'witcher_silver_bear_scabbard'),
    ('lynx',       'witcher_steel_lynx_scabbard',    'witcher_silver_lynx_scabbard'),
    ('gryphon',    'witcher_steel_gryphon_scabbard', 'witcher_silver_gryphon_scabbard'),
    ('wolf',       'witcher_steel_wolf_scabbard',    'witcher_silver_wolf_scabbard'),      # dlc10
    ('manticore',  'witcher_steel_wolf_scabbard_ep2', 'witcher_silver_wolf_scabbard_ep2'), # Blood and Wine (Red Wolf School)
    ('viper',      'scabbard_steel_1_02',            'scabbard_silver_1_05'),
    ('netflix',    'witcher_steel_netflix_scabbard', 'witcher_silver_netflix_scabbard'),
]
CATEGORY = {'steel_scabbards': ('steel', 1), 'silver_scabbards': ('silver', 2)}  # (kind, template column)


def read_list(path):
    items = []
    for line in open(path, encoding='utf-8'):
        line = line.split('#', 1)[0].strip()
        if not line:
            continue
        parts = [p.strip() for p in line.split('|')]
        if len(parts) < 2 or parts[1] not in CATEGORY:
            sys.exit('bad line in %s: %r' % (path, line))
        items.append((parts[0], parts[1]))
    return items


def build(items):
    out = ['<?xml version="1.0" encoding="UTF-16"?>', '<redxml>', '\t<definitions>', '\t\t<items>']
    out.append('\t\t\t<!-- invisible items: the mounted one tells the engine which school scabbard to spawn -->')
    for cat, (kind, _) in CATEGORY.items():
        for school, _, _ in SCHOOLS:
            out.append('\t\t\t<item name="ds_%s_%s" category="ds_%s" equip_template="" attachment_type="skinning">'
                       '<tags>NoShow,NoDrop,EncumbranceOff</tags></item>' % (kind, school, kind))
    out.append('\t\t</items>')
    out.append('\t\t<items_extensions>')
    for name, cat in items:
        kind, idx = CATEGORY[cat]
        out.append('\t\t\t<item_extension name="%s">' % name)
        out.append('\t\t\t\t<variants>')
        for row in SCHOOLS:
            out.append('\t\t\t\t\t<variant equip_template="%s"><item>ds_%s_%s</item></variant>'
                       % (row[idx], kind, row[0]))
        out.append('\t\t\t\t</variants>')
        out.append('\t\t\t</item_extension>')
    out.append('\t\t</items_extensions>')
    out += ['\t</definitions>', '</redxml>', '']
    return '\r\n'.join(out)


def main():
    items = read_list(LIST)
    xml = build(items)
    for path in OUT:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'wb') as f:
            f.write(xml.encode('utf-16'))  # utf-16 codec writes the BOM
    print('%d scabbard definitions, %d schools -> %s' % (len(items), len(SCHOOLS), ', '.join(os.path.relpath(p, ROOT) for p in OUT)))


if __name__ == '__main__':
    main()
