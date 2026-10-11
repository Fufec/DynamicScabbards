// the values match the school options in the menu
enum DSSchoolSet
{
    DS_Set_Equipped = 0, // follow the equipped set
    DS_Set_KaerMorhen = 1,
    DS_Set_Bear = 2,
    DS_Set_Cat = 3,
    DS_Set_Griffin = 4,
    DS_Set_Manticore = 5,
    DS_Set_Wolf = 6,
    DS_Set_Viper = 7,
    DS_Set_ForgottenWolf = 8
}

class DynamicScabbards
{
    // the settings are read from the game's config when needed, so they are always the menu's;
    // without the menu xml (mod.io) the value is "" and the default applies
    function GetOption(option : name, default_value : string) : string
    {
        var value : string;

        value = theGame.GetInGameConfigWrapper().GetVarValue('DSOptions', option);

        if (value == "")
        {
            return default_value;
        }

        return value;
    }

    // mod enabled
    public function IsEnabled() : bool
    {
        return GetOption('DSEnabled', "true") == "true";
    }

    // if true, only chestplate armor piece will be required for the swap to occur
    function IsChestplateMode() : bool
    {
        return GetOption('DSModeChestplate', "false") == "true";
    }

    // DS_Set_Equipped, or a fixed school chosen in the menu
    function GetSchoolMode() : DSSchoolSet
    {
        return (DSSchoolSet)StringToInt(GetOption('DSModeSchool', "0"));
    }

    // armor and swords are read by their transmog appearance
    function PrefersTransmog() : bool
    {
        return GetOption('DSPreferTransmog', "true") == "true";
    }

    // the scabbards get a template override (native transmog) pointing at the school scabbard item:
    // the engine spawns them from that item, and the override is saved with the item
    function SteelCategory() : name
    {
        return 'steel_scabbards';
    }

    function SilverCategory() : name
    {
        return 'silver_scabbards';
    }

    // Some weapons do not match the regular scabbard size. We check for those and exclude them
    function IsExcludedSteelSword(sword : name) : bool
    {
        switch (sword)
        {
            case 'Princessxenthiasword':
            case 'Princessxenthiasword_crafted':
            case 'Robustswordofdolblathanna':
            case 'Robustswordofdolblathanna_crafted':
            case 'Scoiatael sword 1':
            case 'Scoiatael sword 1_crafted':
            case 'Scoiatael sword 2':
            case 'Scoiatael sword 2_crafted':
            case 'Scoiatael sword 3':
            case 'Scoiatael sword 3_crafted':
            case 'Scoiatael sword 4':
            case 'mq7007 Elven Sword':
            case 'Ofir Sabre 1':
            case 'Ofir Sabre 2':
            case 'Hakland Sabre':
            case 'Crafted Ofir Steel Sword':
            case 'Wild Hunt sword 1':
            case 'Knights steel sword 3':
            case 'Olgierd Sabre':
            case 'Steel Vixen':
            case 'Karabela':
            case 'Dyaebl':
            case 'Netflix steel sword':
            case 'Netflix steel sword 1':
            case 'Netflix steel sword 2':
            case 'Cleaver':
            case 'Dwarven sword 1':
            case 'Dwarven sword 1_crafted':
            case 'Dwarven sword 2':
            case 'Dwarven sword 2_crafted':
            case 'Hanza steel sword 3':
            case 'Angivare':
                return true;
        }

        return false;
    }

    function IsExcludedSilverSword(sword : name) : bool
    {
        switch (sword)
        {
            case 'Silver Vixen':
            case 'Netflix silver sword':
            case 'Netflix silver sword 1':
            case 'Netflix silver sword 2':
            case 'Tlareg':
            case 'Tlareg_crafted':
            case 'Dwarven silver sword 1':
            case 'Dwarven silver sword 1_crafted':
            case 'Dwarven silver sword 2':
            case 'Dwarven silver sword 2_crafted':
                return true;
        }

        return false;
    }

    // the vanilla school scabbard items the overrides point at
    function GetSteelScabbard(school : DSSchoolSet) : name
    {
        switch (school)
        {
            case DS_Set_KaerMorhen:        return 'scabbard_steel_1_01';
            case DS_Set_Bear:              return 'scabbard_steel_bear_01';
            case DS_Set_Cat:               return 'scabbard_steel_lynx_01';
            case DS_Set_Griffin:           return 'scabbard_steel_gryphon_01';
            case DS_Set_Manticore:         return 'scabbard_steel_wolf_ep2';
            case DS_Set_Wolf:              return 'scabbard_steel_wolf_01';
            case DS_Set_Viper:             return 'scabbard_steel_1_02';
            case DS_Set_ForgottenWolf:     return 'scabbard_steel_netflix_01';
            default:                       return '';
        }
    }

    function GetSilverScabbard(school : DSSchoolSet) : name
    {
        switch (school)
        {
            case DS_Set_KaerMorhen:        return 'scabbard_silver_1_01';
            case DS_Set_Bear:              return 'scabbard_silver_bear_01';
            case DS_Set_Cat:               return 'scabbard_silver_lynx_01';
            case DS_Set_Griffin:           return 'scabbard_silver_gryphon_01';
            case DS_Set_Manticore:         return 'scabbard_silver_wolf_ep2';
            case DS_Set_Wolf:              return 'scabbard_silver_wolf_01';
            case DS_Set_Viper:             return 'scabbard_silver_1_05';
            case DS_Set_ForgottenWolf:     return 'scabbard_silver_netflix_01';
            default:                       return '';
        }
    }

    // vanilla clears an override with 'None' (transmog menu) or '' (debug command)
    function HasOverride(item : SItemUniqueId) : bool
    {
        return IsNameValid(thePlayer.GetInventory().GetItemTemplateOverride(item));
    }

    // the engine spawns a new entity only on mount
    function Remount(item : SItemUniqueId)
    {
        var inv : CInventoryComponent;

        inv = thePlayer.GetInventory();

        if (inv.IsItemMounted(item))
        {
            inv.UnmountItem(item, true);
            inv.MountItem(item);
        }
    }

    function SetOverride(item : SItemUniqueId, scabbard : name)
    {
        var inv : CInventoryComponent;

        inv = thePlayer.GetInventory();

        if (inv.GetItemTemplateOverride(item) == scabbard)
        {
            return;
        }

        inv.SetItemTemplateOverride(item, scabbard);
        Remount(item);
    }

    function ClearOverride(item : SItemUniqueId)
    {
        if (!HasOverride(item))
        {
            return;
        }

        SetOverride(item, 'None');
    }

    // every sword has its own scabbard item; only the mounted one (of the equipped sword)
    // gets the override, the others are cleared
    function SetCategoryOverride(category : name, scabbard : name)
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;
        var i : int;

        inv = thePlayer.GetInventory();
        ids = inv.GetItemsByCategory(category);

        for (i = 0; i < ids.Size(); i += 1)
        {
            if (inv.IsItemMounted(ids[i]))
            {
                SetOverride(ids[i], scabbard);
            }
            else
            {
                ClearOverride(ids[i]);
            }
        }
    }

    function ClearCategoryOverride(category : name)
    {
        var ids : array<SItemUniqueId>;
        var i : int;

        ids = thePlayer.GetInventory().GetItemsByCategory(category);

        for (i = 0; i < ids.Size(); i += 1)
        {
            ClearOverride(ids[i]);
        }
    }

    function UpdateSteelScabbard(school : DSSchoolSet)
    {
        var inv : CInventoryComponent;
        var sword_steel : SItemUniqueId;

        inv = thePlayer.GetInventory();

        if (!inv.GetItemEquippedOnSlot(EES_SteelSword, sword_steel) ||
            !inv.IsItemSteelSwordUsableByPlayer(sword_steel)        ||
            IsExcludedSteelSword(GetVisibleName(sword_steel)))
        {
            ClearCategoryOverride(SteelCategory());
            return;
        }

        SetCategoryOverride(SteelCategory(), GetSteelScabbard(school));
    }

    function UpdateSilverScabbard(school : DSSchoolSet)
    {
        var inv : CInventoryComponent;
        var sword_silver : SItemUniqueId;

        inv = thePlayer.GetInventory();

        if (!inv.GetItemEquippedOnSlot(EES_SilverSword, sword_silver) ||
            !inv.IsItemSilverSwordUsableByPlayer(sword_silver)        ||
            IsExcludedSilverSword(GetVisibleName(sword_silver)))
        {
            ClearCategoryOverride(SilverCategory());
            return;
        }

        SetCategoryOverride(SilverCategory(), GetSilverScabbard(school));
    }

    function RestoreVanillaScabbards()
    {
        ClearCategoryOverride(SteelCategory());
        ClearCategoryOverride(SilverCategory());
    }

    // set detection: every piece has the school in its name
    function MatchesSchool(armor : name, gloves : name, pants : name, boots : name, school_name : string) : bool
    {
        return (StrContains(armor, school_name)  &&
                StrContains(gloves, school_name) &&
                StrContains(pants, school_name)  &&
                StrContains(boots, school_name));
    }

    // order matters: "Red Wolf" contains "Wolf"
    function GetSchoolFromArmor(armor : name, gloves : name, pants : name, boots : name, out school : DSSchoolSet) : bool
    {
        if (MatchesSchool(armor, gloves, pants, boots, "Starting"))      { school = DS_Set_KaerMorhen;     return true;}
        if (MatchesSchool(armor, gloves, pants, boots, "Bear"))          { school = DS_Set_Bear;           return true;}
        if (MatchesSchool(armor, gloves, pants, boots, "Lynx"))          { school = DS_Set_Cat;            return true;}
        if (MatchesSchool(armor, gloves, pants, boots, "Gryphon"))       { school = DS_Set_Griffin;        return true;}
        if (MatchesSchool(armor, gloves, pants, boots, "Red Wolf"))      { school = DS_Set_Manticore;      return true;}
        if (MatchesSchool(armor, gloves, pants, boots, "Wolf"))          { school = DS_Set_Wolf;           return true;}
        if (MatchesSchool(armor, gloves, pants, boots, "EP1 Witcher"))   { school = DS_Set_Viper;          return true;}
        if (MatchesSchool(armor, gloves, pants, boots, "Netflix"))       { school = DS_Set_ForgottenWolf;  return true;}

        // Built-in compatibility for Witcher School Set Rework and Balance mod
        if (MatchesSchool(armor, gloves, pants, boots, "Kaer Morhen"))   { school = DS_Set_KaerMorhen;     return true;}
        if (MatchesSchool(armor, gloves, pants, boots, "Viper"))         { school = DS_Set_Viper;          return true;}
        if (MatchesSchool(armor, gloves, pants, boots, "Manticore"))     { school = DS_Set_Manticore;      return true;}

        return false;
    }

    // the item the transmog shows, if that setting is on
    function GetVisibleName(item : SItemUniqueId) : name
    {
        var inv : CInventoryComponent;
        var appearance : name;

        inv = thePlayer.GetInventory();
        appearance = inv.GetItemTemplateOverride(item);

        if (PrefersTransmog() && IsNameValid(appearance))
        {
            return appearance;
        }

        return inv.GetItemName(item);
    }

    function GetVisibleItemName(slot : EEquipmentSlots, out item_name : name) : bool
    {
        var inv : CInventoryComponent;
        var item : SItemUniqueId;

        inv = thePlayer.GetInventory();

        if (!inv.GetItemEquippedOnSlot(slot, item))
        {
            return false;
        }

        item_name = GetVisibleName(item);
        return true;
    }

    public function GetEquippedSchool(out school : DSSchoolSet) : bool
    {
        var armor : name;
        var gloves : name;
        var pants : name;
        var boots : name;
        var school_mode : DSSchoolSet;

        school_mode = GetSchoolMode();

        if (school_mode != DS_Set_Equipped)
        {
            school = school_mode;
            return true;
        }

        if (IsChestplateMode())
        {
            // only read chestplate armor piece, it stands for every piece
            if (GetVisibleItemName(EES_Armor, armor))
            {
                return GetSchoolFromArmor(armor, armor, armor, armor, school);
            }
        }
        else
        {
            // all pieces must be equipped
            if (GetVisibleItemName(EES_Armor, armor)   &&
                GetVisibleItemName(EES_Gloves, gloves) &&
                GetVisibleItemName(EES_Pants, pants)   &&
                GetVisibleItemName(EES_Boots, boots))
            {
                return GetSchoolFromArmor(armor, gloves, pants, boots, school);
            }
        }

        return false;
    }

    public function OnEquipmentChanged(slot : EEquipmentSlots)
    {
        switch (slot)
        {
            case EES_SteelSword:
            case EES_SilverSword:
            case EES_Armor:
                SetScabbards();
                return;
            case EES_Boots:
            case EES_Pants:
            case EES_Gloves:
                // In chestplate mode, gloves/pants/boots don't trigger updates
                if (!IsChestplateMode())
                {
                    SetScabbards();
                }
                return;
        }
    }

    public function SetScabbards()
    {
        var school : DSSchoolSet;

        if (!GetWitcherPlayer())
        {
            return;
        }

        if (!IsEnabled() || !GetEquippedSchool(school))
        {
            RestoreVanillaScabbards();
            return;
        }

        UpdateSteelScabbard(school);
        UpdateSilverScabbard(school);
    }

    // the invisible markers of 3.0 (categories ds_steel, ds_silver) can still be in older saves
    public function RemoveOldMarkers()
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;
        var i : int;

        if (!GetWitcherPlayer())
        {
            return;
        }

        inv = thePlayer.GetInventory();
        ids = inv.GetItemsByCategory('ds_steel');
        ArrayOfIdsAppend(ids, inv.GetItemsByCategory('ds_silver'));

        for (i = 0; i < ids.Size(); i += 1)
        {
            if (inv.IsItemMounted(ids[i]))
            {
                inv.UnmountItem(ids[i], true);
            }

            inv.RemoveItem(ids[i], 1);
        }
    }

    // the inventory preview has an inventory of its own, whose items have no override; a scabbard
    // it spawns from there comes from the scabbard's own template (seen with Aerondight)
    function IsScabbard(entity : CItemEntity) : bool
    {
        var category : name;

        category = entity.GetItemCategory();

        return category == SteelCategory() || category == SilverCategory();
    }

    // the preview is an actor, but neither the player nor an NPC, and exists only in a menu
    function IsPreview(entity : CEntity) : bool
    {
        var actor : CActor;
        var player : CR4Player;
        var npc : CNewNPC;

        actor = (CActor)entity;
        player = (CR4Player)entity;
        npc = (CNewNPC)entity;

        return actor && !player && !npc && theGame.GetGuiManager().IsAnyMenu();
    }

    // the template the entity file of an item is named after
    function GetTemplate(item_name : name) : string
    {
        return StrLower(thePlayer.GetInventory().GetItemTemplateByName(item_name));
    }

    // the override of the player's mounted scabbard of that name, '' if it has none
    function GetMountedOverride(scabbard : name) : name
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;
        var i : int;

        inv = thePlayer.GetInventory();
        ids = inv.GetItemsIds(scabbard);

        for (i = 0; i < ids.Size(); i += 1)
        {
            if (inv.IsItemMounted(ids[i]) && HasOverride(ids[i]))
            {
                return inv.GetItemTemplateOverride(ids[i]);
            }
        }

        return '';
    }

    // only the copy from the scabbard's own template is recognized:
    // a template that does not match the entity file never remounts anything
    function IsOwnTemplateCopy(entity : CItemEntity, scabbard : name, appearance : name) : bool
    {
        var own_template : string;

        own_template = GetTemplate(scabbard);

        return (own_template != ""                      &&
                own_template != GetTemplate(appearance) &&
                StrEndsWith(StrLower(entity.GetReadableName()), own_template + ".w2ent"));
    }

    // the preview's item gets the override; only that scabbard is remounted
    function SetPreviewOverride(preview : CEntity, entity : CItemEntity, appearance : name)
    {
        var inv : CInventoryComponent;
        var item : SItemUniqueId;

        inv = ((CGameplayEntity)preview).GetInventory();

        if (!inv)
        {
            return;
        }

        item = inv.GetItemByItemEntity(entity);

        if (!inv.IsIdValid(item))
        {
            return;
        }

        inv.SetItemTemplateOverride(item, appearance);
        inv.UnmountItem(item, true);
        inv.MountItem(item);
    }

    public function OnItemAttached(entity : CItemEntity, parent_entity : CEntity, item_name : name)
    {
        var appearance : name;

        if (!IsScabbard(entity) || !IsPreview(parent_entity))
        {
            return;
        }

        appearance = GetMountedOverride(item_name);

        if (appearance == '' || !IsOwnTemplateCopy(entity, item_name, appearance))
        {
            return;
        }

        SetPreviewOverride(parent_entity, entity, appearance);
    }
}

@addField(CR4Player)
public var ds : DynamicScabbards;

@addMethod(CR4Player)
public function InitDynamicScabbards()
{
    var currentVersion : string = "4.00";
    var currentVersionFloat : float = 4.00;

    var inGameConfig : CInGameConfigWrapper;

    this.ds = new DynamicScabbards in this;
    inGameConfig = theGame.GetInGameConfigWrapper();

    if (!inGameConfig.GetVarValue('DSOptions', 'DSVersion'))
    {
        inGameConfig.SetVarValue('DSOptions', 'DSEnabled', true);
        inGameConfig.SetVarValue('DSOptions', 'DSModeChestplate', false);
        inGameConfig.SetVarValue('DSOptions', 'DSModeSchool', 0);
        inGameConfig.SetVarValue('DSOptions', 'DSPreferTransmog', true);
        inGameConfig.SetVarValue('DSOptions', 'DSVersion', currentVersion);

        // without the menu xml (mod.io) nothing is stored, so there is nothing to save
        if (inGameConfig.GetVarValue('DSOptions', 'DSVersion'))
        {
            theGame.SaveUserSettings();
        }
    }
    else if (StringToFloat(inGameConfig.GetVarValue('DSOptions', 'DSVersion')) < currentVersionFloat)
    {
        inGameConfig.SetVarValue('DSOptions', 'DSPreferTransmog', true); // new in 4.00
        inGameConfig.SetVarValue('DSOptions', 'DSVersion', currentVersion);
        theGame.SaveUserSettings();
    }
}

// the instance is not saved, so it is created on first use
@addMethod(CR4Player)
function GetDynamicScabbards() : DynamicScabbards
{
    if (!ds)
    {
        InitDynamicScabbards();
    }

    return ds;
}

// covers installing or updating the mod on an existing save
@wrapMethod(CR4Game)
function OnAfterLoadingScreenGameStart()
{
    wrappedMethod();

    thePlayer.GetDynamicScabbards().RemoveOldMarkers();
    thePlayer.GetDynamicScabbards().SetScabbards();
}

// Ciri and back; covers installing the mod while playing as Ciri
@wrapMethod(CR4Game)
function OnPlayerChanged()
{
    wrappedMethod();

    thePlayer.GetDynamicScabbards().SetScabbards();
}

@wrapMethod(W3PlayerWitcher)
function EquipItemInGivenSlot(item : SItemUniqueId, slot : EEquipmentSlots, ignoreMounting : bool, optional toHand : bool) : bool
{
    var result : bool;

    result = wrappedMethod(item, slot, ignoreMounting, toHand);

    if (!result)
    {
        return result;
    }

    thePlayer.GetDynamicScabbards().OnEquipmentChanged(slot);

    return result;
}

@wrapMethod(W3PlayerWitcher)
function UnequipItemFromSlot(slot : EEquipmentSlots, optional reequipped : bool) : bool
{
    var result : bool;

    result = wrappedMethod(slot, reequipped);

    // reequipped: an equip into the slot follows and updates the scabbards
    if (!result || reequipped)
    {
        return result;
    }

    thePlayer.GetDynamicScabbards().OnEquipmentChanged(slot);

    return result;
}

// every item the engine attaches, to anyone: the inventory preview is checked for its scabbards
@wrapMethod(CItemEntity)
function OnAttachmentUpdate(parentEntity : CEntity, itemName : name)
{
    wrappedMethod(parentEntity, itemName);

    // an event: no bare return; the main menu has no player
    if (GetWitcherPlayer())
    {
        thePlayer.GetDynamicScabbards().OnItemAttached(this, parentEntity, itemName);
    }
}

// update the menu swf: the school choice and the transmog setting need the mod enabled,
// the chestplate armor piece only setting needs the mod enabled and the equipped set followed.
// Disabling the options to interact with the menu when the mod is turned off prevents race conditions and exceptions
@addMethod(CR4IngameMenu)
function UpdateDSMenuOptions(modEnabled : bool, schoolMode : DSSchoolSet)
{
    var dataArray : CScriptedFlashArray;
    var schoolOption : CScriptedFlashObject;
    var chestplateOption : CScriptedFlashObject;
    var transmogOption : CScriptedFlashObject;

    dataArray = m_flashValueStorage.CreateTempFlashArray();

    schoolOption = m_flashValueStorage.CreateTempFlashObject();
    schoolOption.SetMemberFlashUInt('tag', NameToFlashUInt('DSModeSchool'));
    schoolOption.SetMemberFlashBool('disabled', !modEnabled);
    dataArray.PushBackFlashObject(schoolOption);

    chestplateOption = m_flashValueStorage.CreateTempFlashObject();
    chestplateOption.SetMemberFlashUInt('tag', NameToFlashUInt('DSModeChestplate'));
    chestplateOption.SetMemberFlashBool('disabled', !modEnabled || schoolMode != DS_Set_Equipped);
    dataArray.PushBackFlashObject(chestplateOption);

    transmogOption = m_flashValueStorage.CreateTempFlashObject();
    transmogOption.SetMemberFlashUInt('tag', NameToFlashUInt('DSPreferTransmog'));
    transmogOption.SetMemberFlashBool('disabled', !modEnabled);
    dataArray.PushBackFlashObject(transmogOption);

    m_flashValueStorage.SetFlashArray('options.update_disabled', dataArray);
}

@wrapMethod(CR4IngameMenu)
function OnOptionValueChanged(groupId : int, optionName : name, optionValue : string)
{
    var result : bool;
    var groupName : name;
    var inGameConfig : CInGameConfigWrapper;
    var modEnabled : bool;
    var schoolMode : DSSchoolSet;

    result = wrappedMethod(groupId, optionName, optionValue);

    if (result)
    {
        return result;
    }

    inGameConfig = theGame.GetInGameConfigWrapper();
    groupName = inGameConfig.GetGroupName(groupId);

    if (groupName != 'DSOptions')
    {
        return result;
    }

    if (optionName == 'DSEnabled' || optionName == 'DSModeSchool')
    {
        modEnabled = inGameConfig.GetVarValue(groupName, 'DSEnabled');
        schoolMode = (DSSchoolSet)StringToInt(inGameConfig.GetVarValue(groupName, 'DSModeSchool'));

        UpdateDSMenuOptions(modEnabled, schoolMode);
    }

    // the main menu has no player
    if (GetWitcherPlayer())
    {
        thePlayer.GetDynamicScabbards().SetScabbards();
    }

    return result;
}

// disable the dependent options when the submenu opens (before changing any value); read from config, the main menu has no player
@wrapMethod(CR4IngameMenu)
function OnShowOptionSubmenu(actionType : int, menuTag : int, id : string)
{
    var result : bool;
    var inGameConfig : CInGameConfigWrapper;
    var modEnabled : bool;
    var schoolMode : DSSchoolSet;

    result = wrappedMethod(actionType, menuTag, id);

    if (id == "DS_settings")
    {
        inGameConfig = theGame.GetInGameConfigWrapper();
        modEnabled = inGameConfig.GetVarValue('DSOptions', 'DSEnabled');
        schoolMode = (DSSchoolSet)StringToInt(inGameConfig.GetVarValue('DSOptions', 'DSModeSchool'));

        UpdateDSMenuOptions(modEnabled, schoolMode);
    }

    return result;
}
