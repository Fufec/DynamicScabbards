# Dynamic Scabbards

Monorepo for the **Dynamic Scabbards** mod (The Witcher 3) and its patch.
Nexus: <https://www.nexusmods.com/witcher3/mods/11253>

## Structure

| Folder | Component | Tag prefix |
|---|---|---|
| `mods/modDynamicScabbards/` | main mod: scripts, menu strings and `blob0.bundle` with the scabbard variants | `core` |
| `mods/mod0_DS_WPIAO_Patch/` | Wear Preview Items As Outfits patch | `wpiao` |
| `bin/` | menu config (`user_config_matrix`), ships with core | `core` |
| `bundle_src/` | XML source of the bundle, generated | - |
| `tools/` | `scabbards.toml` (covered scabbard definitions), `gen_variants.py`, `pack_bundle.py` | - |

Each component is versioned **independently**; the source of truth is the
`version` field in its `witcherscript.toml`. The repo root mirrors the game
install layout (`mods/` + `bin/`).

## How it works (3.0)

The bundle adds `<variant>` rules (vanilla `item_extension`) to every scabbard
definition listed in `tools/scabbards.toml`. While the invisible marker item of a
school (`ds_steel_<school>`, `ds_silver_<school>`) is mounted, the engine spawns
the sword's bound scabbard from that school's template instead of its own. The
script only keeps the right marker mounted; the engine handles draws, loads,
scenes, fast travel and the player switch to Ciri and back.

Mods that read the mounted scabbard entity therefore see the school scabbard
and work without patches: Swords and Meditation, Swords on Hip (and the When
Cloaked variant), Auto Hide Weapons for Cloaks. **The old SOH and AHW patches
must be removed** when updating from 2.x. Wear Preview Items As Outfits still
needs its patch, because the school has to follow the outfit, not the armor.

Scabbards not listed in `tools/scabbards.toml` keep their own look. Definition
names that are not loaded (a mod that is not installed) are harmless.

## Adding a scabbard

1. Add a line `"definition name" = "origin"` under `[steel_scabbards]` or
   `[silver_scabbards]` in `tools/scabbards.toml`.
2. `python3 tools/gen_variants.py` regenerates `bundle_src/`.
3. `tools/pack_bundle.py` rebuilds `blob0.bundle` and `metadata.store`
   (Windows, needs `wcc_lite` from Script Merger).

Or open an issue with the definition name of the scabbard.

## Release

Push a tag `core/vX.Y.Z` or `wpiao/vX.Y.Z` matching the manifest version; the
workflow builds the zip, uploads it to Nexus and creates a GitHub release.
