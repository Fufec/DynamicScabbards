# Dynamic Scabbards

Monorepo for the **Dynamic Scabbards** mod (The Witcher 3) and its patches.
Nexus: <https://www.nexusmods.com/witcher3/mods/11253>

## Structure

| Folder | Component | Tag prefix |
|---|---|---|
| `mods/modDynamicScabbards/` | main mod | `core` |
| `mods/mod0_DS_SOH_Patch/` | Swords on Hip / SOHWC patch | `soh` |
| `mods/mod0_DS_WPIAO_Patch/` | Wear Preview Items As Outfits patch | `wpiao` |
| `mods/mod0_DS_AHW_Patch/` | Auto Hide Weapons for Cloaks patch | `ahw` |
| `bin/` | menu config (`user_config_matrix`, core only) | — |

Each component is versioned **independently**; the source of truth is the
`version` field in its `witcherscript.toml`. The repo root mirrors the game
install layout (`mods/` + `bin/`).
