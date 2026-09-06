# Dynamic Scabbards: co jsme zjistili o enginu (6. 9. 2026)

Poznámky z celodenního zkoumání, jak ve Witcher 3 (next-gen 4.04) fungují pochvy, aby šlo udělat
„true replacement“ bez patchů pro cizí mody. Vše níže je ověřené ve hře přes testovací mod
`modDSTest` (trace do `user.settings`), pokud není řečeno jinak.

## 1. Pochvy na úrovni inventáře

- Pochva je obyčejný item kategorie `steel_scabbards` / `silver_scabbards`, tagy `NoShow, NoDrop,
  EncumbranceOff`, `attachment_type="skinning"`. Definice v `gameplay\items\_technical_items_defs.xml`
  (+ `def_item_weapons_scabbards.xml`, `dlc18_netflix_swords.xml`, dlc10 pro vlka, W3EE atd.),
  celkem 119 definic (seznam v příloze).
- Každý meč má v XML `<bound_items>` se svou pochvou. Engine ji vytvoří, když meč přijde do
  inventáře, a **namountuje ji pokaždé, když mountuje meč**: nasazení, load, začátek scény, fast travel
  a **tasení**.
- Když bound pochva v inventáři chybí (smazali jsme ji), engine si ji při dalším mountu meče
  **vyrobí znovu** z definice. Odstranění vanilla pochvy tedy nic neřeší.
- Na kategorii může být namountovaná **jen jedna** pochva. Mount jedné odmountuje druhou
  („obě najednou“ nejde).
- Každý meč v inventáři má svou pochvu (uživatel měl 23 ocelových), takže heuristiky typu
  „jediný kandidát“ jsou k ničemu.
- Skriptem přidané itemy (`AddAnItem`) **se ukládají do savu**. Tagy přidané skriptem
  (`AddItemTag`) se **neukládají**, item modifiery (`SetItemModifierInt`) **ano** (vanilla je používá
  pro `ammo_current`). Původní závěr „item po loadu zmizí“ byl chybný, posuzovali jsme to podle tagu.
- Po loadu je namountované jen to, co je nasazené nebo bound. Náš item zůstane v inventáři
  nenamountovaný a neviditelný (NoShow).
- Ze skriptu nejde zjistit, kterou pochvu má meč bound (žádné API), ani změnit šablonu entity itemu.

## 2. Časování loadu a spawnu entit

- Při loadu ve chvíli `CActor.OnAppearanceChanged` jsou záznamy inventáře už kompletní (meč nasazený
  a mounted, bound pochva mounted), ale **žádná entita ještě neexistuje**. Engine je spawne do ~0,1 s
  a změny inventáře udělané před tím **zahodí**.
- Entita naší pochvy vzniká **1 až 4 snímky** po `MountItem` (měřeno per-frame timerem).
- Použitelná podmínka „engine je hotov“ je `GetItemEntityUnsafe(vanilla pochvy) != NULL`.
  Poll po 0,05 s ji chytí hned na prvním tiku. `GetEngineTimeAsSeconds` se s loadem obnovuje ze savu.

## 3. Save

- `CR4Game.OnSaveStarted` běží **před** snapshotem (item odstraněný v něm v savu není),
  `OnSaveCompleted` přijde ~0,09 s poté. Odstranit a vrátit pochvu kolem savu funguje, ale při každém
  (auto)savu pochva na ~0,2 s zmizí.

## 4. Události, které chodí (a nechodí)

| událost | chodí? | kdy |
|---|---|---|
| `CActor.OnAppearanceChanged` (na hráči) | ano | load, fast travel, přepnutí Ciri → Geralt |
| `CActor.OnBlockingSceneStarted` | ano | začátek každé scény |
| `CR4Player.OnBlockingSceneEnded` | **nikdy** (pro hráče) | – |
| `CItemEntity.OnAttachmentUpdate(parent, itemName)` | ano | pokaždé, když engine připne pochvu na aktora: tasení, load, scéna, fast travel, i pro naši pochvu; v inventáři i pro paperdoll (`parent=other`) |
| `W3PlayerWitcher.EquipItemInGivenSlot` / `UnequipItemFromSlot` | ano | menu i skriptované scény (holič sundá meče a vrací zbroj, Fugas sáhne na rukavice) |
| `OnClosingMenu` | ano | inventář i pause menu |

- `OnAttachmentUpdate` je jediné místo, kde je vidět každý mount od enginu. Vanilla ho používá
  na update zvuků zbroje.
- Scény: holič meče na dobu dialogu odloží (`GetItemEquippedOnSlot` = false), po dialogu je vrací přes
  equip API. Cutscéna po Imlerithovi na svém začátku namountuje bound pochvu meče, který byl v ruce.

## 5. Vyzkoušené přístupy a verdikty

| přístup | výsledek |
|---|---|
| **item swap**: odmountovat vanilla, přidat a namountovat školní pochvu (item z vanilla definic) + poll na spawn vanilla entity | funguje pro load, fast travel, holiče, Ciri, save, výměnu v menu; **selhává při každém tasení**, engine vrátí bound pochvu a naši vyhodí |
| item swap + oprava z `OnAttachmentUpdate` (hned i příští snímek) | funguje, ale při každém tasení a schování bliknutí (1–2 snímky, zničení a spawn entity); uživatel odmítl |
| vanilla namountovaná + skrytá, naše vedle | nejde, jedna namountovaná na kategorii |
| vanilla pochvu odstranit | engine si ji vyrobí znovu při tasení |
| odstranit naši před savem (`OnSaveStarted`) | funguje, ale bliká při každém savu |
| modifier místo tagu jako značka | funguje, brání hromadění po loadech (v savu zůstane 1 skrytý item na kategorii) |
| **původní mechanismus** (main): školní šablona vložená do appearance komponenty Geralta + `SetHideInGame` vanilla entity | žádný flicker, engine s ničím nebojuje; potřebuje patche pro S&M (kopíruje šablonu entity), SOH, AHW; timery by šly nahradit `OnAttachmentUpdate` |

Lag při testech: způsobuje ho trace (`SaveUserSettings()` při každém záznamu, HUD zprávy), ne mod.

## 6. Jak cizí mody čtou pochvy

- **Swords and Meditation**: projde všechny itemy kategorie a pro každý s entitou vytvoří u ohně kopii
  přes `CreateEntity(LoadResource(entity.GetReadableName()))`, tedy ze **šablony entity**. Dvě
  namountované pochvy = dvě kopie.
- **Swords on Hip**: přesouvá entity pochev.
- **AHW**: schovává entity itemů podle kategorie.
- Žádný z nich se nedívá na vzhled vložený do Geraltovy appearance, proto původní mechanismus potřebuje patche.

## 7. Nová cesta: varianty šablony v definici itemu (`items_extensions`)

Vanilla XML umí dát itemu víc `equip_template` a engine vybere podle toho, jaké jiné itemy aktor má:

```xml
<items_extensions>
    <item_extension name="Starting Armor">
        <variants>
            <variant equip_template="t_01_mg__viper_lvl3_armor_stand">
                <item>_armor_stand</item>
            </variant>
            <variant equip_template="t_01a_mg__viper_lvl3_armor_stand" category="gloves" all="true">
                <item>_armor_stand</item>
            </variant>
        </variants>
    </item_extension>
</items_extensions>
```

- Podmínky: `<item>jméno</item>` (vanilla takto řeší vzhled kalhot pod zbrojí, vlasy pod kapucí; dlc__hoods
  používá `<item_category>`), atribut `all="true"` = všechny podmínky naráz, bez něj stačí kterákoli.
- `equip_template` je **jméno šablony** bez cesty (`witcher_steel_lynx_scabbard`), stejně jako v
  definicích itemů.
- `_armor_stand` je marker item: `category="decorations" equip_template="" attachment_type="skinning"`.
- Existuje i `<collapse><item_cond name="..." collapse="false"/></collapse>` (dlc18).

Návrh: XML s `item_extension` pro každou vanilla pochvu a sedmi variantami (jedna na školu), podmínka
= marker item `dsc_school_<škola>` definovaný jako `_armor_stand`. Skript jen podle `GetEquippedSchool`
namountuje správný marker. Engine pak sám spawnuje školní šablonu pro bound pochvu: při tasení, loadu,
ve scénách, bez výměn a bez blikání. S&M, SOH i AHW vidí správnou entitu. Odinstalace: definice zmizí,
marker v savu je neznámý item.

Neověřeno, rozhodne test ve hře:

1. Platí `<item>` pro přítomnost markeru, nebo jen pro namountovaný? (Podle vanilla použití na zbroje
   spíš namountovaný; `MountItem` na marker bez šablony vanilla dělá u stojanu.)
2. Přehodnotí engine varianty hned při mountu markeru, nebo až při dalším mountu pochvy?
3. Stačí XML v mod bundlu, nebo je potřeba DLC s `.reddlc` (`CR4DefinitionsDLCMounter` ukazuje na
   adresář, XML může ležet i v mod bundlu, jak to dělá W3EE)? Všechny mody přidávající definice jsou DLC.

Balení: bundle (POTATO70, položky 320 B) + `metadata.store`, u DLC + `.reddlc` (CR2W). Nástroj: `wcc_lite`
(starý Modkit, `pack` a `metadatastore`) nebo REDkit.

## 8. Nástroje a postupy

- Syntax check: `npx -y tree-sitter-cli@0.26.8 parse <soubor>` v `C:\Users\fufec\projects\tree-sitter-witcherscript`
  (0 ERROR/MISSING). Pozor: `entry` je klíčové slovo, `StringToName` neexistuje, wrap volá `wrappedMethod`
  právě jednou, exec funkce nejde volat ze skriptu, víceřádkové `+` řetězce parser odmítá.
- Log: `LogChannel` v next-gen nic nezapisuje. Trace jde přes `CInGameConfigWrapper.SetVarValue` +
  `theGame.SaveUserSettings()` do `Documents\The Witcher 3\user.settings`; hra přijala jen 8 proměnných
  z XML (`DSTestLog1..8`), proto jsou v každé 3 záznamy oddělené ` || `.
- `DisplayHudMessage` s dlouhými texty sráží fps na jednotky, do trace nepatří.
- Timery: `AddTimer(name, period, repeats)`, per-frame (period 0) vanilla běžně používá; opakovaný timer
  hru nezmrazí. Latentní funkce (`Sleep`) jen ve state machine.
- Bundle: Python parser ve scratchpadu (`bundle2.py`): hlavička 32 B, položky 320 B, komprese 0/zlib=1/lz4=4,5.
- Testovací mod `modDSTest` (jen ve hře, není v repu): `ds_trace(1/0)`, `ds_dump(note)`, `ds_names(cat)`,
  `ds_purge(cat, name)`, `ds_savetest(1/0)`, `ds_attachfix(0..3)`, `ds_include(1/0)`, `ds_hide_vanilla(cat)`,
  `ds_mount_vanilla(cat)`, `ds_remove_vanilla(cat)`, `ds_hud(1/0)`. Fakty `dstest_*` se ukládají do savu,
  po testu vypnout.

## Příloha: definice pochev (jméno itemu → jméno šablony)

Ocel (`steel_scabbards`):

```
Ciri Zireael Sword Scabbard      scabbard_01_wa__ciri
Long Steel Sword Scabbard        scabbard_steel_1_01
NPC Witcher Steel Sword Scabbard scabbard_steel_1_01
Sabre Scabbard 01/01_2/01_3      scabbard_sabre_1_01
Sabre Scabbard 02                scabbard_sabre_1_02
Sabre Scabbard 03                scabbard_sabre_1_03
Sabre Scabbard 04                scabbard_sabre_1_01_03
Sabre Scabbard 05                scabbard_sabre_1_04
Sabre Scabbard 06                scabbard_sabre_1_05
Sabre Scabbard 07                scabbard_sabre_1_06
Sabre Scabbard v01               scabbard_sabre_1v_01
Sabre Scabbard v02               scabbard_sabre_1v_02
scabbard_nilf_lvl1..4            scabbard_nilf_lvl1..4
scabbard_nomansland_lvl1..4      scabbard_nomansland_lvl1..4
scabbard_novigrad_lvl1..5        scabbard_novigrad_lvl1..5
scabbard_sabre_lvl1..4           scabbard_sabre_lvl1..4
scabbard_skellige_lvl1..4        scabbard_skellige_lvl1..4
scabbard_wild_hunt_lvl1          scabbard_wild_hunt_lvl1
scabbard_steel_1_01              scabbard_steel_1_01
scabbard_steel_1_02              scabbard_steel_1_02
scabbard_steel_1_02_02           scabbard_steel_1_02_02
scabbard_steel_1_02_03           scabbard_steel_1_02_03
scabbard_steel_1_03              scabbard_steel_1_03
scabbard_steel_1_04              scabbard_steel_1_04
scabbard_steel_1_04_02           scabbard_steel_1_04_02
scabbard_steel_1_05              scabbard_steel_1_05
scabbard_steel_1_06              scabbard_steel_1_06
scabbard_steel_1_wood            scabbard_steel_1_wood
scabbard_steel_1v_01             scabbard_steel_1v_01
scabbard_steel_2_01              scabbard_steel_2_01
scabbard_steel_2v_01             scabbard_steel_2v_01
scabbard_steel_3_01..3_05        scabbard_steel_3_01..3_05
scabbard_steel_3v_01             scabbard_steel_3v_01
scabbard_steel_bear_01           witcher_steel_bear_scabbard
scabbard_steel_gryphon_01        witcher_steel_gryphon_scabbard
scabbard_steel_lynx_01           witcher_steel_lynx_scabbard
scabbard_steel_netflix_01        witcher_steel_netflix_scabbard   (dlc18_netflix_swords.xml)
scabbard_steel_wolf_01           (dlc10, v tomto výpisu chybí)
scabbard_steel_nilfgaard_01      nilfgaardian_scabbard_lvl1
scabbard_steel_nilfgaard_01_02   nilfgaardian_scabbard_lvl1_02
scabbard_steel_nilfgaard_02..04  nilfgaardian_scabbard_lvl2..4
scabbard_steel_nomansland_01..04 nomansland_scabbard_lvl1..4
scabbard_steel_novigradian_01..05 novigraadan_scabbard_lvl1..5
scabbard_steel_skellige_01..04   skellige_scabbard_lvl1..4
scabbard_steel_vixen             scabbard_steel_3_08              (def_item_swords_vixen.xml)
NPC Scabbard 1/2/HOS/Knight/Sabre/Short  scabbard_npc_*         (W3EE)
```

Stříbro (`silver_scabbards`):

```
NPC Witcher Silver Sword Scabbard scabbard_silver_1_01
Witcher Silver Sword Scabbard     scabbard_silver_1_01
scabbard_silver_1_01..1_10, 1_12, 1_13   stejné jméno šablony
scabbard_silver_1v_01, 1v_02, 1v_10, 1v_11
scabbard_silver_2_01..2_04, 2v_01
scabbard_silver_3_01..3_05, 3v_01
scabbard_silver_bear_01           witcher_silver_bear_scabbard
scabbard_silver_gryphon_01        witcher_silver_gryphon_scabbard
scabbard_silver_lynx_01           witcher_silver_lynx_scabbard
scabbard_silver_netflix_01        witcher_silver_netflix_scabbard
scabbard_silver_wolf_01           (dlc10)
scabbard_silver_vixen             scabbard_silver_3_08
scabbard_silver_zirael            scabbard_silver_1_zirael
```

Školní šablony pro varianty: `witcher_{steel,silver}_{bear,lynx,gryphon,netflix}_scabbard`,
`scabbard_steel_1_01` / `scabbard_silver_1_01` (Kaer Morhen), `scabbard_steel_1_02` / `scabbard_silver_1_05`
(Viper), vlk z dlc10 (`witcher_steel_wolf_scabbard` / `witcher_silver_wolf_scabbard`, ověřit v dlc10 XML).
