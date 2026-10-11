# Dynamic Scabbards

Match the scabbards of your swords with your witcher armor, for The Witcher 3
Remastered (game version 5.0).
Nexus: <https://www.nexusmods.com/witcher3/mods/11253>

Version 3.0 for game version 4.04 is tagged `core/v3.0.0`.

## Structure

| Folder | Content |
|---|---|
| `mods/modDynamicScabbards/` | the mod: `content/scripts/DynamicScabbards.ws`, menu strings (`content/*.w3strings`, source `translation.csv`) |
| `bin/` | menu config (`user_config_matrix`) |

The version is the `version` field in `mods/modDynamicScabbards/witcherscript.toml`.
The repo root mirrors the game install layout (`mods/` + `bin/`).

## How it works (4.0)

The mod is script-only. Remastered can give an item a template override (the
native transmog). While Geralt wears a witcher set, the scabbard of each equipped
sword gets an override pointing at the school scabbard and is remounted once.
From then on the engine spawns the school scabbard itself on every mount: draws,
loads, scenes, fast travel. Only the mounted scabbard has the override; the
scabbards of the other swords are cleared. The override is saved with the item.

Mods that read the mounted scabbard entity see the school scabbard, as with 3.0
(not yet tested with their Remastered versions). The Wear Preview Items As
Outfits patch is not needed anymore: the native transmog takes its place.

The inventory preview keeps its own copies of the items, with their overrides.
A scabbard copy it creates itself (seen with Aerondight) has none, and gets the
override of Geralt's scabbard.

## Settings

Options > Mods > Dynamic Scabbards:

- **Mod enabled**
- **Use scabbards from witcher school**: Equipped (follow the armor) or a fixed school
- **Only chestplate armor piece required**
- **Use transmog appearance** (default on): armor and swords are read by their
  transmog appearance, so the scabbard follows what Geralt looks like

Without the menu (mod.io) the defaults apply: enabled, equipped school, full
set, transmog appearance.

## Uninstall

The overrides are saved with the scabbards. Before removing the mod, turn it
off in the menu or take off a piece of the witcher set, save, then remove the
mod. Otherwise the scabbards keep their last school look.

## Excluded swords

Swords whose blade does not fit a regular scabbard keep their own:
`IsExcludedSteelSword` / `IsExcludedSilverSword` in the script. Add the item
name there, or open an issue with it.

## Strings

`translation.csv` is encoded with [w3strings Remastered](https://www.nexusmods.com/witcher3/mods/13094)
(format 164, UTF-8), id space 11253, one file per language with its
`;meta[language=xx]` line:

```
w3stringsr -i 11253 translation.csv en.w3strings
```

## Release

Push a tag `core/vX.Y.Z` matching the manifest version; the workflow builds the
zip, uploads it to Nexus and creates a GitHub release.
