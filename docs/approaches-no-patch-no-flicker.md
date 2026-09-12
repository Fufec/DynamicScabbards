# Dynamic Scabbards bez patchů a bez blikání: průzkum cest (7. 9. 2026)

Navazuje na `engine-findings.md`. Otázka zněla: jde udělat výměnu pochvy tak, aby
(1) cizí mody (Swords and Meditation, Swords on Hip, Auto Hide Weapons) fungovaly **bez patchů** a
(2) pochva **nikdy neblikla**, ani při tasení? Prošel jsem zdrojáky těch tří modů, vanilla skripty
(API entit, komponent, inventáře), vanilla i modové item XML (varianty), bundly ostatních
nainstalovaných modů a formát `.reddlc`.

**Krátká odpověď:** obě podmínky splňuje jediná cesta, a to nechat **engine sám spawnovat školní
šablonu jako entitu vanilla pochvy** přes `items_extensions` varianty podmíněné marker itemem
(cesta A níže). Všechno ostatní poruší aspoň jednu podmínku, a to z principu, ne kvůli detailům.

---

## 1. Co přesně cizí mody potřebují (a proč dnes chtějí patch)

Všechny tři mody pracují **výhradně s entitou itemu pochvy z inventáře**. Žádný z nich se nedívá
na Geraltovu appearance, na tagy ani na nic, co bychom mohli podstrčit skriptem.

| Mod | Jak najde pochvu | Co s ní dělá | Zdroj |
|---|---|---|---|
| Swords and Meditation | `GetAllItems` → filtr kategorie `steel_scabbards` / `silver_scabbards` → `GetItemEntityUnsafe(id)` | kopie u ohně: `CreateEntity(LoadResource(entity.GetReadableName()))`; originál skryje `entity.GetMeshComponent().SetVisible(false)` | `modSwordscampfire/content/scripts/local/swordscampfire.ws:366-413` |
| Swords on Hip | totéž (`Check_Steel_Carrrying`) | kopie na bok / na Klepnu ze stejného `GetReadableName()`; originál skryje přes `GetMeshComponent()` → `SetVisible(false)` | `modWeaponsCarrying/content/scripts/local/weapons_carrying.ws` (viz i `mods/mod0_DS_SOH_Patch`) |
| Auto Hide Weapons | `GetItemsByCategory('steel_scabbards')` → `GetItemEntityUnsafe(id)` | `GetMeshComponent().SetVisible(visible)` | `mod_AHW/content/scripts/local/AHW.ws:72-98` |

Z toho plyne tvrdý požadavek pro „bez patchů“: **entita, kterou vrátí `GetItemEntityUnsafe` pro
namountovanou pochvu, musí sama být školní pochva.** Musí mít školní šablonu (kvůli kopiím) a její
`GetMeshComponent()` musí být školní mesh (kvůli skrývání). Nenamountované itemy entitu nemají
(`GetItemEntityUnsafe` vrací NULL), takže mody vidí jen tu jednu namountovanou na kategorii.

## 2. Co engine skriptu dovolí (inventura API)

Ověřeno grepem přes `content0/scripts` (soubory jsou UTF-16, grep přes `scratchpad/ugrep.py`).

**Inventář** (`game/components/inventoryComponent.ws`):
- `GetItemEntityUnsafe` (1137), `MountItem(id, toHand, force)` (1143), `UnmountItem(id, destroyEntity)`
  (1146), `DespawnItem` (1376), `GetItemByItemEntity` (664). Nic, co by měnilo šablonu, entitu nebo
  mesh existujícího itemu. Bound itemy jsou čistě nativní a berou se z definice meče
  (`<bound_items>`, u hráče `<player_override><bound_items>` v `def_item_weapons.xml`).
- Na kategorii je namountovaná jen jedna pochva (ověřeno ve hře, viz `engine-findings.md`).

**Entita itemu** (`game/gameplay/items/itemEntity.ws`): `GetMeshComponent()` je `import final`
(nativní), `OnAttachmentUpdate(parent, itemName)` je skriptový event (hookovatelný, chodí při každém
připnutí pochvy k hráči).

**Entita** (`engine/entity.ws`): `SetHideInGame` (243), `CreateAttachment` (344),
`GetComponentByClassName` (251). `GetReadableName()` (369) je **skriptová** funkce: vrátí cestu
šablony z `ToString()`. Dá se tedy wrapnout, a právě z ní si S&M i SOH berou šablonu pro kopie.
`ApplyAppearance` (384) přepíná appearance v rámci jedné šablony (vanilla pochvy školní appearance
nemají).

**Komponenty** (`engine/components.ws`): `CDrawableComponent` umí jen `IsVisible`, `SetVisible`,
`SetCastingShadows` (417-426). `CMeshComponent` nemá ve skriptech žádné API, mesh vyměnit nejde.
`CAppearanceComponent` (`engine/appearanceComponent.ws`): `IncludeAppearanceTemplate` /
`ExcludeAppearanceTemplate` (mechanismus mainu).

**Nativní funkce nejde wrapovat.** V žádném z ~50 nainstalovaných modů není `@wrapMethod` ani
`@replaceMethod` na `import` funkci; hookují se jen skriptové eventy (`OnAppearanceChanged`,
`OnSaveStarted`, `OnAttachmentUpdate`, `OnBlockingSceneStarted`...). `GetItemEntityUnsafe`,
`GetMeshComponent` ani `SetVisible` tedy podstrčit nejde.

**Definice itemů (varianty).** Vanilla mechanismus, kterým engine vybírá `equip_template` podle toho,
co má vlastník namountované. Syntaxe podle průzkumu všech vanilla + DLC XML:

```xml
<item_extension name="JMÉNO VANILLA ITEMU">          <!-- přidává varianty existujícímu itemu -->
  <variants>
    <variant equip_template="ŠABLONA" [category="KAT"] [all="true"]>
      <item>JMÉNO ITEMU</item>                        <!-- podmínka: konkrétní item -->
      <item_category>KATEGORIE</item_category>        <!-- podmínka: libovolný item kategorie -->
    </variant>
  </variants>
</item_extension>
```

- `category="gloves"` na variantě = zkrácená podmínka „nějaké rukavice“ (zbroje bez rukávů, 424×).
- `all="true"` = všechny podmínky najednou (AND), jinak stačí jedna (OR).
- `<item_extension>` existuje jen s `name=`, **žádná varianta na celou kategorii**. Přes 2 000 výskytů,
  všechny jmenné.
- Precedenty přesně našeho vzoru (mod mění šablonu **vanilla** itemu podmíněnou **svým** itemem):
  `dlc__hoods_extensions.xml` (vlasy Geralta podle kapuce, podmínka `<item_category>ArdHoodClassic`),
  `dlckillingmonsterscloak_extensions.xml` (vlasy podle `<item>Killing Monsters Cloak</item>`).
  Oba fungují u uživatele ve hře.
- Vanilla marker bez šablony: `<item name="_armor_stand" category="decorations" equip_template=""
  attachment_type="skinning">` (`_technical_items_defs.xml:14`), použitý ve 119 variantách v
  `_armor_stand_variants_extension.xml`. Stojan na zbroj (`armorStandEntity.ws`) marker sám
  nemountuje (mountuje jen zbroj, případně vše s `force=true`), jen ho má v inventáři.
- Vanilla použití (rukavice → zbroj bez rukávů, maska → vlasy) vylučuje, že by stačilo item *mít v
  batohu*: podmínky se vyhodnocují nad namountovanými itemy. Marker tedy budeme mountovat, jako
  kapuci nebo plášť. Jestli `MountItem` projde i s `equip_template=""`, ukáže test; záložní šablona
  je vanilla dummy `items\quest_items\q001\q001_item__dummy.w2ent`.

## 3. Přehled cest

| # | Cesta | Bliká při tasení | Patche | Verdikt |
|---|---|---|---|---|
| A | **Varianty v definici + marker item** (engine spawnuje školní šablonu jako bound pochvu) | ne | jen WPIAO | **jediná, která splňuje obojí** |
| B | Main: mesh v Geraltově appearance + skrytá vanilla, nově skrývat v `OnAttachmentUpdate` | ne | S&M, SOH, AHW, WPIAO | bez patchů to nejde z principu (kap. 1) |
| B' | B + wrap `GetReadableName` (kopie S&M/SOH dostanou školní cestu) | ne | AHW, S&M/SOH skrývání | skrývání jde přes nativní `GetMeshComponent`, nejde obejít |
| C | Item swap (větev `experimental/item-swap`) | ano, každé tasení | jen WPIAO | mrtvá: engine při tasení mountuje bound pochvu, jedna na kategorii |
| C' | C + oprava v `OnAttachmentUpdate` | 1–2 snímky | jen WPIAO | odmítnuto uživatelem |
| C'' | C + „dvojník“: skrytá volná entita, která se ukáže jen v mezeře mezi zničením naší a spawnem vanilla | riziko 1 snímku vanilla | jen WPIAO | složité, křehké, závisí na pořadí eventů, které neznáme |
| D | Volná školní entita připnutá jako dítě vanilla pochvy + `SetVisible(false)` na vanilla mesh | ne | S&M, SOH, AHW | mody skrývají/kopírují vanilla mesh, naše dítě zůstane |
| E | Náš item v jiné kategorii (obě namountované) | ne | S&M, SOH, AHW | mody iterují `steel_scabbards`, vidí vanilla |
| F | Nahradit vanilla šablony pochev po cestě šablonami s více appearance a přepínat `ApplyAppearance` | ne | S&M, SOH (kopie má výchozí appearance) | REDkit obsah pro 119 šablon, override vanilla souborů, konflikty s mesh mody |
| G | Změnit bound pochvu meče (`<player_override><bound_items>`) | ne | jen WPIAO | jde jen editací definice každého meče, tedy vanilla XML |
| H | Zabránit remountu při tasení | – | – | tasení je C++ (`MountItem(meč, toHand)` mountuje bound itemy), skript to nevidí |

Poznámka k C'': mezera vzniká proto, že engine zničí naši entitu synchronně při mountu vanilla a
nová entita spawnuje 1–4 snímky po `MountItem` (naměřeno). Dvojník by musel být připnutý dopředu a
přepínaný z `OnParentAttachmentBroken` / `OnAttachmentUpdate`; vanilla by se navíc musela skrýt ve
stejném snímku, kdy se poprvé vykreslí, což nemáme ověřené. Neuvedeno jako doporučení.

## 4. Cesta A podrobně

### 4.1 Princip

DLC/bundle přidá pro každou známou pochvu `item_extension` se sedmi variantami, každá podmíněná jedním
marker itemem. Skript jen udržuje správný marker v inventáři. Engine pak spawnuje bound pochvu meče
rovnou jako školní: při tasení, po loadu, u holiče, po scéně, po fast travelu, vždy, protože ji
spawnuje ze své definice. Nic se nevyměňuje, nic nebliká. S&M kopíruje `GetReadableName()` =
školní šablona, SOH i AHW skrývají `GetMeshComponent()` = školní mesh. Žádný patch kromě WPIAO
(ten jen mění, jak se určuje škola, a zůstává beze změny).

```xml
<items>
  <item name="dsc_steel_lynx" category="dsc_marker" equip_template="" attachment_type="skinning">
    <tags>NoShow,NoDrop,EncumbranceOff</tags></item>
  <!-- 7 škol × ocel/stříbro = 14 markerů, ať jde vyloučit meč jen v jedné kategorii -->
</items>
<items_extensions>
  <item_extension name="scabbard_steel_skellige_03">
    <variants>
      <variant equip_template="witcher_steel_lynx_scabbard"><item>dsc_steel_lynx</item></variant>
      <variant equip_template="witcher_steel_bear_scabbard"><item>dsc_steel_bear</item></variant>
      <!-- gryphon, wolf (dlc10), viper, kaer morhen, netflix -->
    </variants>
  </item_extension>
</items_extensions>
```

Vanilla XML se **needitují**. Soubor je nový a na vanilla pochvy se jen odkazuje jménem. Seznam se
generuje skriptem ze všech bundlů (content0, dlc, W3EE...), dnes 119 definic (příloha v
`engine-findings.md`); rozšíření o pochvy dalších modů je jeden řádek na pochvu (např. Brothers in
Arms: `olgierd_sabre_curved_scabbard`, `def_item_bia_scabbards.xml`). Pochva, která v seznamu není,
si nechá svůj vzhled, což je u modových pochev s vlastním slotem (BiA má `l_hip_weapon_slot`) spíš
správně než špatně.

### 4.2 Co zůstane ve skriptu a co zmizí

Zůstane: `GetEquippedSchool` + režim hrudní plát / celý set, výjimky mečů, nastavení, WPIAO patch,
spouštěče `HandleScabbardUpdate` (equip/unequip), pending po zavření menu, zapnutí/vypnutí modu.

Nové jádro (v tvém stylu, dvě kopie pro ocel a stříbro):

```
function SetScabbards()
    // škola a výjimky jako dnes
    UpdateSteelMarker(marker_name)   // odstraní ostatní dsc_steel_*, přidá a namountuje chtěný
    UpdateSilverMarker(marker_name)  // '' = žádný marker = vanilla vzhled
    // když se marker změnil a engine varianty sám nepřepočítá: UnmountItem(pochva, true) + MountItem(pochva)
```

Zmizí: poll `SetScabbardsWhenReady`, timery, `OnAppearanceChanged`, `OnBlockingSceneEnded`,
`OnAttachmentUpdate`, item swap (`MountDynamicScabbard`, `FindMountedVanillaScabbard`, restore
vanilla), modifier marker. Vypnutí modu = odebrat markery. Odinstalace = definice markerů zmizí,
engine je při loadu zahodí jako neznámé itemy a pochvy jsou vanilla.

### 4.3 Očekávané chování (co má test potvrdit)

| Situace | Dnes (item swap) | Cesta A |
|---|---|---|
| tasení / schování | bliká | nic, engine mountuje bound = školní |
| load | poll, vanilla max 1 interval | školní od prvního snímku (marker je v savu) |
| save / autosave | nic | nic |
| holič, Ciri, Imlerith, fast travel | poll / hooky | nic k řešení |
| výměna meče v menu | bliknutí vyměněného meče | bound pochva nového meče spawne rovnou školní, tedy bez bliknutí |
| změna školy (zbroj) | respawn pochvy | respawn pochvy (stejně jako dnes) |
| vypnutí modu / odinstalace | restore / skrytý item v savu | odebrat marker / neznámý item se zahodí |

### 4.4 Balení: mod bundle, nebo DLC

- Ani jeden z nainstalovaných modů nepřidává **nový** XML soubor přes obyčejný mod bundle. Bundly v
  `mods/` obsahují jen přepisy existujících cest (`mod000_Patch_BIA-W3EER`, `modBrothersInArms`).
  Každý mod, který přidává itemy, je DLC s `.reddlc` (hoods, KMC, BiA, W3EE, EldenRoach, S&M, SOH).
  Počítejme tedy s DLC; test s `modDSVariantsTest` (nový XML v mod bundlu) to rozhodne.
- `wcc_lite pack` + `wcc_lite metadatastore` (Script Merger\Tools) fungují, testovací bundle má
  stejnou strukturu jako bundly DLC modů (ověřeno hexdumpem: tabulka entries, LZ4 komprese typ 5).
- `.reddlc` je CR2W soubor a **umíme ho vyrobit sami** (Python), nepotřebujeme REDkit ani WolvenKit:
  - hlavička 40 B + 10 tabulek po 12 B (offset, počet, crc); verze 162/163;
  - `crc32` hlavičky = standardní CRC32 přes prvních 160 B, kde je místo crc zapsáno `0xDEADBEEF`
    (sedí u hoods, S&M, KMC, BiA, W3EE a dalších);
  - tabulka stringů: CRC32 surových bajtů; tabulka jmen: `{u32 offset, u32 hash}` s
    `hash = FNV-1a 32 bit přes ASCII jméno včetně koncové nuly` (ověřeno na všech 19 jménech);
  - crc u exportů nezávisí na datech (stejná hodnota pro stejnou třídu, u některých 0), stačí opsat;
  - W3EE má tři DLC se stejným `id` (`dlc_014_001`) a s nesedícím crc hlavičky a hra je načte,
    takže engine je tolerantní; přesto zapíšeme vše správně.
  - Minimální obsah: `CDLCDefinition{ id, mounters[ CR4DefinitionsDLCMounter{ definitionXmlFilePath
    = "dlc\dlcDynamicScabbards\data\gameplay\items\" }, CR4DefinitionsNGPlusDLCMounter{ ...items_plus\ } ] }`.
    `definitionXmlFilePath` bere adresář (hoods) i konkrétní soubor (KMC).
- NG+ má v `gameplay\items_plus` **vlastní kompletní sadu** definic (2 842 itemů, jména pochev
  stejná). Rozšíření musí být i tam, jinak v NG+ školní pochvy nebudou. Proto ten NGPlus mounter.

### 4.5 Otevřené otázky a test

Testovací mod `modDSVariantsTest` je ve hře (markery `dsc_school_lynx`, `dsc_school_bear`, varianty
pro 8 pochev, které používáš). Postup po restartu je v předchozí zprávě v chatu; DSTest execy:
`ds_school(marker)`, `ds_school_present(marker)`, `ds_remount_vanilla(cat)`, `ds_template(cat)`.

1. **Načte se nový XML z mod bundlu?** `ds_school('dsc_school_lynx')` → „definition not found“ = ne,
   jdeme přes DLC (`.reddlc` vyrobíme, viz 4.4).
2. **Projde `MountItem` na markeru bez šablony?** HUD `mounted=true/false`. Když ne: zkusit
   `ds_school_present` (jen přítomnost), případně dummy šablona.
3. **Přepočítá engine varianty sám při mountu markeru?** Když se pochva nezmění hned, pomůže
   `ds_remount_vanilla('steel_scabbards')`; pak stačí explicitní remount při změně školy.
4. **Drží to tasení, F5/F9, fast travel, holič?** Očekávám ano, protože o entitu se stará engine.
5. **Toleruje `item_extension` neznámé jméno itemu?** Rozhodne, jestli můžeme shipnout seznam pochev
   cizích modů v jednom souboru, nebo po volitelných DLC.
6. NG+ (`items_plus`) až s DLC.

### 4.6 Rizika

- Netestované chování C++ variant u itemů kategorie, pro kterou je vanilla nikdy nepoužívá
  (pochvy). Ošetří test 1–4.
- Konflikt s jiným modem nastane jen tehdy, když by někdo definoval `item_extension` pro stejnou
  pochvu. Dnes nikdo.
- Distribuce: DS přestane být čistě skriptový mod (bundle + `metadata.store` + případně DLC složka).
  Vanilla soubory se nemění, Script Merger se netýká.

## 5. Co jsme zjistili navíc

- `CEntity.GetReadableName()` je skript, ne native. Jde wrapnout a S&M i SOH z něj berou šablonu pro
  kopie. Samo o sobě to patche neodstraní (skrývání jde přes nativní `GetMeshComponent`), ale kdyby
  někdy bylo potřeba podstrčit cizímu modu jinou šablonu, je to místo.
- Vanilla `GiveStartingItems` (`r4Player.ws:14468`) mountuje itemy s tagem `Scabbard` skriptem; s
  tasením to nesouvisí, to je C++.
- Vanilla dummy entity pro případný viditelně prázdný item: `items\quest_items\q001\q001_item__dummy.w2ent`,
  `q001_dummy_for_geralt.w2ent`.
- Nástroje ve `scratchpad`: `ugrep.py` (UTF-16 grep), `listbundle.py` (výpis položek bundlu),
  `w3/bundle2.py` (extrakce), rozbalené XML v `vanillaxml/`, `dlcxml/`, `othermods/`, `.reddlc` v
  `reddlc/` a `othermods/`.

## Dodatek 2026-09-11: co ještě bylo prověřeno v `witcher3.exe`

Řetězce v `bin/x64_dx12/witcher3.exe` (UTF-16) obsahují slovník XML parseru definic
itemů i registrace nativních funkcí po třídách. Z toho plyne:

**Slovník `<item>` a rozšíření.** Parser zná jen tyto uzly: `items`, `item`,
`items_extensions`, `item_extension` (pouze atribut `name`), `variants`, `variant`
(`equip_template`, `category`, `all`, děti `item` a `item_category`), `collapse`
(`item_cond`, `category_cond`), `bound_items`, `player_override`,
`player_override_extension`, `anim_switches`, `slot_items`, `base_abilities`,
`recycling_parts`, `tags`. Rozšíření podle kategorie neexistuje: cílem rozšíření je
vždy jméno definice. Atributy `<item>`, které vanilla XML nepoužívá, ale parser je
zná: `appearance`, `color_variant`, `upgrade_based_template`, `hold_template`
(použité u bomb a šipek). Nic z toho nemění cíl na úrovni kategorie.
`player_override` vanilla používá jen pro jiné `bound_items` u hráče.

**Nativní funkce, které skripty nedeklarují.** `CDrawableComponent` má navíc
`EnableLightChannels` a `AreLightChannelsEnabled`. `CItemEntity` má jen
`GetMeshComponent` a `GetParentEntity` a vlastnost `m_timeToDespawn`.
`CMeshComponent` nemá žádnou nativní funkci, jen vlastnost `m_mesh`.
`CAppearanceComponent`: `IncludeAppearanceTemplate`, `ExcludeAppearanceTemplate`,
`ApplyAppearance`, `GetAppearance` (vše deklarované). Žádné `SetMesh`,
`SetTemplate`, `SetItemEquipTemplate`, `ReloadDefinitions`.

**Import vlastností.** Kompilátor má hlášku
`Property '%ls' exists but was not imported from C++ code.`, takže `import var m_mesh`
v modu nepomůže: vlastnost musí být exportovaná z C++. Podobně
`Native function '%ls' was not exported from class '%ls' in C++ code.` a
`Native class function '%ls' cannot be wrapped.`.

**Závěr.** Jediný vstup do výběru šablony za běhu je stav namountovaných itemů
(podmínky variant). Cíl varianty je vždy jméno definice pochvy, načtené při
startu. Hypotetická API, která by problém řešila úplně dynamicky (hook na výběr
šablony při mountu, `SetItemEquipTemplate(itemId, ...)`, `SetMesh` na komponentě,
rozšíření podle kategorie), v enginu nejsou.

**Samodiagnostika pokrytí.** `CDefinitionsManagerAccessor.GetItemsWithTag('EncumbranceOff')`
plus filtr `GetItemCategory(name) == 'steel_scabbards' / 'silver_scabbards'` vrátí
všechny definice pochev načtené v dané hře, včetně modových. Skript tak umí
porovnat nahrané definice se seznamem, který rozšiřujeme, a nepokryté pochvy
vypsat (exec pro hlášení chyb, případně jednorázová hláška).

## Dodatek 2026-09-11 (2): průzkum AMM, Eternal Hunt a WPIAO

Zdroje: AMM 4.04 (`modAMM/content/scripts/local/AMM.ws`, 6 435 řádků),
Eternal Hunt (github apokryphus/eternal-hunt, `EH.ws` 176 k řádků + WeaponStuff),
Wear Preview Items As Outfits (`modWearPreviewItemsAsOutfits`, 4 299 řádků).
Dále znovu S&M (`swordscampfire.ws`), SOH (`weapons_carrying.ws`), SOHWC, AHW.

**Všechny tři mody pracují se stejnými třemi primitivy jako DS 2.2.x:**
`IncludeAppearanceTemplate`/`ExcludeAppearanceTemplate` na `CAppearanceComponent`
hráče (AMM `GearToogle`, EH `AlternateSteelScabbardManage`: stejný seznam školních
šablon jako DS), `CreateEntity` + `CreateAttachment` pro vlastní entity (EH
zbraně, kopie přes `GetReadableName()`), a `SetHideInGame`/`SetVisible` na
namountované item entitě (AMM `HideScabs`: `GetItemsByCategory` -> všechny
entity kategorie -> `SetHideInGame(true)`, časovač 0,35 s po spawnu meče; EH
`SteelSwordScabbardSetVisible` stejně přes `SetVisible`). Nikdo nemění šablonu
ani mesh existující item entity. Nikdo nepoužívá varianty pro hráče.

**WPIAO: `MountItem(id, toHand, force = true)` přidá další entitu bez vyhození
ostatních itemů stejné kategorie** (komentář autora v `PreviewOutfitManager.ws`:
"Adds a new entity without replacing others, stacking multiple items in the same
category's internal stack"). `force = false` kategorii vylučuje. Interní stack
se neukládá, po spawnu hráče se staví znovu, proto WPIAO po loadu remountuje.
Skrývání dělá přes `@wrapMethod(CItemEntity) OnAttachmentUpdate` a časovač
0,001 s (`SetHideInGame`), protože mapa id -> entita je hned po mountu zastaralá.
Pro DS to znamená: náš item by mohl být namountovaný vedle bound pochvy (test 3
z plánu, dosud nespuštěný). Vanilla pochvu je ale pořád nutné skrýt a mody ji
pořád čtou, takže je to jen jiná podoba přístupu B (item místo appearance
šablony), ne cesta bez zásahů.

**Jak mody vybírají pochvu:** S&M i SOH projdou `GetAllItems`, filtrují
kategorii a kopii vytvoří z první položky, která má entitu
(`GetItemEntityUnsafe(...).GetReadableName()`); mesh skrývají u všech, které
entitu mají. AHW, EH i AMM projdou `GetItemsByCategory` a skryjí/ukážou všechny
entity kategorie. Při dvou namountovaných pochvách by tedy kopie S&M/SOH
závisela na pořadí položek (řeší jen wrap `GetReadableName`), skrývání by
fungovalo u všech.

**Modové meče a pochvy:** BiA definuje `olgierd_sabre_curved_scabbard`, ale
žádný hráčský meč ji neváže (Olgierdova šavle pro hráče má přes
`player_override` vanilla `Sabre Scabbard 02`). Z nainstalovaných modů žádný
hráčský meč neváže nevanilla pochvu. Meče s vlastní tvarovanou pochvou by DS
stejně vylučoval (seznam `IsExcludedSteelSword` už obsahuje Olgierd Sabre,
Ofir Sabre, Karabela apod.).

**Závěr průzkumu:** žádný z prozkoumaných modů nenašel způsob, jak měnit
šablonu namountované pochvy za běhu. Přístup A (varianty) zůstává jediný, který
nepotřebuje skrývání ani wrapy. Force mount je jediný nový poznatek a patří
k přístupu B.

## Implementace cesty A na větvi (11. 9. 2026)

Rozhodnutí: vyzkoušet varianty naostro. Stav na větvi `experimental/item-swap`:

- `tools/scabbards.txt`: seznam 133 definic pochev (93 ocelových, 40 stříbrných) ze všech bundlů
  nainstalované hry (content0, dlc10, bob, W3EE, Brothers in Arms). Původ je u každého řádku.
- `tools/gen_variants.py`: z toho seznamu vygeneruje `bundle_src/gameplay/items/dynamic_scabbards.xml`
  a totéž do `items_plus` pro NG+. 14 neviditelných itemů `dsc_steel_<škola>` / `dsc_silver_<škola>`
  (kategorie `dsc_steel`, `dsc_silver`, prázdná šablona, tagy `NoShow,NoDrop,EncumbranceOff`) a ke každé
  pochvě `item_extension` se sedmi variantami. Šablony škol: `scabbard_steel_1_01` (Kaer Morhen),
  `witcher_steel_{bear,lynx,gryphon,wolf,netflix}_scabbard`, `scabbard_steel_1_02` (Zmije); stříbro
  analogicky, Zmije `scabbard_silver_1_05`. Manticora používá vlčí šablonu z dlc10 jako dosud
  (vanilla má pro ni kopii `witcher_steel_wolf_scabbard_ep2` v bob se stejným meshem a texturami).
- `tools/pack_bundle.sh`: `wcc_lite pack` + `metadatastore` do `mods/modDynamicScabbards/content/`
  (`blob0.bundle` 11 kB, `metadata.store`). Bundle i XML jsou v repu, release nepotřebuje wcc_lite.
- `DynamicScabbards.ws`: jádro přepsané. `SetSchoolItem(category, item_name)` drží v inventáři a
  namountovaný právě jeden neviditelný item kategorie (ostatní odebere, chybějící přidá přes
  `AddAnItem` a `MountItem`), `''` odebere všechny. `UpdateSteelScabbard` / `UpdateSilverScabbard`
  vyberou item podle školy, u vyloučeného nebo nepoužitelného meče item odeberou.
  `RestoreVanillaScabbards` = odebrat oba. Zmizel modifier, item swap, poll `SetScabbardsWhenReady`,
  timer, hook `OnBlockingSceneEnded`. `HandleScabbardUpdate` volá `SetScabbards` rovnou.
  `OnAppearanceChanged` zůstal jen jako pojistka po loadu (item je v savu a zůstává namountovaný,
  takže normálně nic nedělá). WPIAO patch se nemění (`GetEquippedSchool`, `GetSchoolFromArmor`,
  `chestplate_mode`, `SetPendingUpdate` zůstaly).
- Ve hře: nový core + bundle nainstalované, `modDSVariantsTest` smazán (jeho rozšíření by se s novými
  potkala na stejných pochvách), `modDSTest` nahrazen malým: `ds_scabs()`, `ds_template(cat)`,
  `ds_set()`, `ds_purge_old()` (pozůstatky item swapu s modifikátorem), `ds_school_item(cat, item)`,
  `ds_school_item_clear(cat)`.

Test (co má potvrdit):

1. Kompilace a start. `ds_scabs()`: v `dsc_steel` a `dsc_silver` po nasazení školní zbroje jeden item M.
2. `ds_template('steel_scabbards')`: namountovaná pochva meče má školní šablonu.
3. Tasení, schování, F5/F9, rychlé cestování, holič, rozhovor, Imlerith (scéna, kde se dřív vracela
   vanilla pochva), Ciri, meditace, výměna meče a zbroje v menu: bez bliknutí vanilla pochvy.
4. Změna školy: jak vypadá přepnutí (respawn pochvy, případný snímek vanilla).
5. Vypnutí modu v nastavení: vanilla pochvy hned. Zapnutí: školní hned.
6. Vlčí meč (definice pochvy z dlc10) se školní zbrojí jiné školy: rozšíření z mod bundlu zabírá i na
   definici z DLC.
7. Vyloučený meč (např. Olgierd Sabre): vanilla pochva, item kategorie odebraný.
8. NG+ save, pokud je: školní pochvy = `items_plus` se z mod bundlu načetl.
9. Odinstalace (smazat bundle i skripty): load savu s neviditelným itemem, hra nesmí nic hlásit,
   pochvy vanilla.
10. Až po testech: rozšíření na pochvu, jejíž mod není nainstalovaný (řádek s vymyšleným jménem
    v `scabbards.txt`), rozhodne, jestli může být seznam modových pochev v jednom souboru.

### Doplněk 12. 9. 2026

- Manticora má vlastní neviditelný item `dsc_*_manticore` a šablonu `witcher_*_wolf_scabbard_ep2`
  z Blood and Wine, tedy tu, kterou váží mantikoří meče ve vanille. 16 itemů, 8 variant na pochvu.
- Sezon Burz Witcher's Gear má vlastní pochvy `sezonburzsteelscabbard` / `sezonburzsilverscabbard`
  (vlastní `.w2ent` v `dlc\sezonburz`) vázané na své meče. Do seznamu se nepřidávají, dokud o to
  někdo nepožádá; bez rozšíření si meče nechají svou pochvu.
- `HandleScabbardUpdate` volá `SetScabbards` i v inventáři (náhled ukazuje namountované itemy).
  Odklad do zavření menu z 2.0.0 neměl v historii zdůvodnění, zůstal jen pro nastavení a WPIAO.
  Bez meče v slotu se školní item nechává, aby výměna meče v menu nedělala odebrání a přidání.
- Scéna kámen, nůžky, papír s Ciri: vanilla pochvy během scény, po scéně správně. Diagnostika v
  `modDSTest` (záznamy na začátku a konci scény do `user.settings`, `ds_last()`), čeká na data.
- Neviditelné itemy a jejich kategorie přejmenovány z `dsc_` na `ds_` (`ds_steel_lynx`, kategorie
  `ds_steel`, `ds_silver`). Itemy `dsc_*` ze starých testovacích savů zůstanou bez definice, což je
  zároveň test bodu 9.
- Odklad aktualizace do zavření menu (`update_pending`, `OnClosingMenu`) vyhozen. Důvod pro něj byl,
  že deset změn v nastavení znamenalo deset přestaveb vzhledu přes `IncludeAppearanceTemplate`, což
  lagovalo. Teď je jedno volání jen kontrola namountovaného itemu. Nastavení i patch pro WPIAO
  volají `SetScabbards` rovnou.
- Wrapy událostí (`OnBlockingSceneStarted`, `OnBlockingSceneEnded`) se píší bez návratového typu,
  kompilátor jinak hlásí "Event function cannot return implicit a value".
- Bod 10 ověřen: `item_extension` na jméno, které žádná definice nemá (`ds_test_missing_scabbard`),
  hra načte bez následků, itemy i ostatní rozšíření ze stejného souboru fungují. Seznam smí
  obsahovat pochvy modů, které hráč nemá nainstalované.
- Bez laga: deset přepnutí modu v nastavení za sebou nic nezpomalí.
- Scéna kámen, nůžky, papír vyřešena: hra sundá rukavice (`UnequipItemFromSlot(EES_Gloves)` mimo menu
  a mimo scénu), v režimu celé sady tím sada není celá a skript školní itemy odebere; po vrácení
  rukavic je přidá. Varianty ve scéně fungují, pochva byla školní od začátku scény.
- Návrat z Ciri na Geralta funguje bez hooku (item je v inventáři a namountovaný). Pro instalaci
  modu během hraní za Ciri přidán hook na `CR4Game.OnPlayerChanged`, který C++ volá po výměně hráče.
- Zamrzání při změnách výbavy dělal jen testovací mod (`SaveUserSettings` při každém záznamu).


### Výsledky testů a úklid (12. 9. 2026 večer)

- Odinstalace: složka modu smazána, save načten bez chyb, vanilla pochvy. Testovací mod musel
  jít pryč zároveň, wrapuje třídu modu.
- Vlčí meč s medvědí zbrojí: medvědí pochva (rozšíření definice z dlc10 funguje).
- Kaer Morhen přes `additem('Starting Armor')` atd.: funguje, nová hra se netestovala.
- Ciri: mod vypnutý před sekcí a zapnutý během ní → po návratu školní pochvy; zapnutý před sekcí
  a vypnutý během ní → po návratu vanilla. Instance po návratu čte nastavení čerstvě.
- Kompatibilní mody bez patchů: Swords and Meditation, Auto Hide Weapons for Cloaks, Swords on Hip
  a Swords on Hip When Cloaked (ten přebíjí soubor SOH prioritou). WPIAO s novým patchem funguje.
- Měření (`ds_bench` v testovacím modu, `GetLocalTimeAsMilliseconds`): `GetItemsByCategory` 0,7 µs,
  `GetEquippedSchool` 10,4 µs, celé `SetScabbards` 27 µs. Rozdělení aktualizace po slotech
  (v historii f1a34c7) by ušetřilo ~8 µs při výměně meče a stálo ~10 µs při změně zbroje; vráceno,
  `SetScabbards` zůstává jediným vstupem.
- Pojmenování: neviditelný item je „marker“ (`SetMarker`, `ClearMarker`, `IsMarkerMounted`,
  `GetSteelMarker`/`GetSilverMarker`, `SteelCategory()`/`SilverCategory()`).
- PR #2 (mkhl, pevná škola z menu) sloučen do mainu a přenesen: `DSSchoolSet` má `DS_Set_Equipped = 0`
  a hodnoty podle položek menu, `school_mode` je enum, položky XML zapisují `DSModeSchool`,
  závislé volby se zašedí (`UpdateDSMenuOptions`). PR #1 (výjimka Viroledan Blade) doplněn merge mainu.
- Jádro má `GetVisibleItemName(slot, out name)`; patch pro WPIAO wrapuje jen ji a je bez logiky setu.
- Výjimka `Angivare` (hlášeno na Nexusu): definice se jmenuje stejně ve vanille i ve W3EE,
  `Angivare_crafted` jako item nikde neexistuje, jen jako jméno v receptu W3EE.
- Úklid: patche SOH a AHW smazány včetně balení a workflow, `docs/dsc_variants_test.xml` smazán,
  verze core 3.0.0, patch WPIAO 2.0.0, nový README.
