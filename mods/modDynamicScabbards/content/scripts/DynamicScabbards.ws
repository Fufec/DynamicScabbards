enum DSSchoolSet
{
    DS_Set_KaerMorhen,
    DS_Set_Bear,
    DS_Set_Cat,
    DS_Set_Griffin,
    DS_Set_Manticore,
    DS_Set_Wolf,
    DS_Set_Viper,
    DS_Set_ForgottenWolf
}

class DynamicScabbards
{
    var enabled : bool; // mod enabled
    var chestplate_mode : bool; // if true, only chestplate armor piece will be required for the swap to occur

    public function SetEnabled(value : bool) 
    { 
        enabled = value; 
    }

    public function SetChestplateMode(value : bool) 
    { 
        chestplate_mode = value; 
    }

    public function IsEnabled() : bool 
    { 
        return enabled; 
    }

    // The bundle adds variants to every scabbard definition: while the invisible school item is mounted,
    // the engine spawns the bound scabbard from the school template. The script only keeps the right item mounted
    function GetSteelSchoolItemCategory() : name
    {
        return 'ds_steel';
    }

    function GetSilverSchoolItemCategory() : name
    {
        return 'ds_silver';
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

    function GetSteelSchoolItemName(school: DSSchoolSet) : name
    {
        switch (school)
        {
            case DS_Set_KaerMorhen:        return 'ds_steel_kaermorhen';
            case DS_Set_Bear:              return 'ds_steel_bear';
            case DS_Set_Cat:               return 'ds_steel_lynx';
            case DS_Set_Griffin:           return 'ds_steel_gryphon';
            case DS_Set_Manticore:         return 'ds_steel_manticore';
            case DS_Set_Wolf:              return 'ds_steel_wolf';
            case DS_Set_Viper:             return 'ds_steel_viper';
            case DS_Set_ForgottenWolf:     return 'ds_steel_netflix';
            default:                       return '';
        }
    }

    function GetSilverSchoolItemName(school: DSSchoolSet) : name
    {
        switch (school)
        {
            case DS_Set_KaerMorhen:        return 'ds_silver_kaermorhen';
            case DS_Set_Bear:              return 'ds_silver_bear';
            case DS_Set_Cat:               return 'ds_silver_lynx';
            case DS_Set_Griffin:           return 'ds_silver_gryphon';
            case DS_Set_Manticore:         return 'ds_silver_manticore';
            case DS_Set_Wolf:              return 'ds_silver_wolf';
            case DS_Set_Viper:             return 'ds_silver_viper';
            case DS_Set_ForgottenWolf:     return 'ds_silver_netflix';
            default:                       return '';
        }
    }

    function RemoveSchoolItems(category : name)
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
                inv.UnmountItem(ids[i], true);
            }

            inv.RemoveItem(ids[i], 1);
        }
    }

    function IsSchoolItemMounted(category : name, item_name : name) : bool
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;

        inv = thePlayer.GetInventory();
        ids = inv.GetItemsByCategory(category);

        return ids.Size() == 1 && inv.GetItemName(ids[0]) == item_name && inv.IsItemMounted(ids[0]);
    }

    // AddAnItem returns nothing without the bundle
    function EnsureSchoolItemMounted(category : name, item_name : name)
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;

        if (IsSchoolItemMounted(category, item_name))
        {
            return;
        }

        RemoveSchoolItems(category);

        inv = thePlayer.GetInventory();
        ids = inv.AddAnItem(item_name, 1, true, true);

        if (ids.Size() > 0)
        {
            inv.MountItem(ids[0]);
        }
    }

    function UpdateSteelScabbard(school : DSSchoolSet)
    {
        var inv : CInventoryComponent;
        var sword_steel : SItemUniqueId;
        var sword_name : name;

        inv = thePlayer.GetInventory();

        if (!GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, sword_steel))
        {
            return; // no sword, keep the school item
        }

        sword_name = inv.GetItemName(sword_steel);

        if (!inv.IsItemSteelSwordUsableByPlayer(sword_steel) || IsExcludedSteelSword(sword_name))
        {
            RemoveSchoolItems(GetSteelSchoolItemCategory());
            return;
        }

        EnsureSchoolItemMounted(GetSteelSchoolItemCategory(), GetSteelSchoolItemName(school));
    }

    function UpdateSilverScabbard(school : DSSchoolSet)
    {
        var inv : CInventoryComponent;
        var sword_silver : SItemUniqueId;
        var sword_name : name;

        inv = thePlayer.GetInventory();

        if (!GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, sword_silver))
        {
            return; // no sword, keep the school item
        }

        sword_name = inv.GetItemName(sword_silver);

        if (!inv.IsItemSilverSwordUsableByPlayer(sword_silver) || IsExcludedSilverSword(sword_name))
        {
            RemoveSchoolItems(GetSilverSchoolItemCategory());
            return;
        }

        EnsureSchoolItemMounted(GetSilverSchoolItemCategory(), GetSilverSchoolItemName(school));
    }

    function RestoreVanillaScabbards()
    {
        RemoveSchoolItems(GetSteelSchoolItemCategory());
        RemoveSchoolItems(GetSilverSchoolItemCategory());
    }

    // Set detection: full-set or chestplate-only mode based on chestplate_mode setting
    function MatchesSchool(armor : name, gloves : name, pants : name, boots : name, school_name : string) : bool
    {
        if (chestplate_mode)
        {
            return StrContains(armor, school_name);
        }
        else
        {
            return (StrContains(armor, school_name) && 
                    StrContains(gloves, school_name) && 
                    StrContains(pants, school_name) && 
                    StrContains(boots, school_name));
        }
    }

    // order matters: "Red Wolf" before "Wolf", vanilla names before Set Rework names
    function GetSchoolFromArmor(armor : name, gloves : name, pants : name, boots : name, out school: DSSchoolSet) : bool
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

    public function GetEquippedSchool(out school: DSSchoolSet) : bool
    {
        var armor : SItemUniqueId;
        var gloves : SItemUniqueId;
        var pants : SItemUniqueId;
        var boots : SItemUniqueId;

        var witcher : W3PlayerWitcher;
        var inv : CInventoryComponent;

        witcher = GetWitcherPlayer();
        inv = thePlayer.GetInventory();

        if (chestplate_mode)
        {
            // only read chestplate armor piece
            if (witcher.GetItemEquippedOnSlot(EES_Armor, armor))
            {
                return GetSchoolFromArmor(inv.GetItemName(armor), '', '', '', school);
            }
        }
        else
        {
            // all pieces must be equipped
            if (witcher.GetItemEquippedOnSlot(EES_Armor, armor)   && 
                witcher.GetItemEquippedOnSlot(EES_Gloves, gloves) && 
                witcher.GetItemEquippedOnSlot(EES_Pants, pants)   && 
                witcher.GetItemEquippedOnSlot(EES_Boots, boots))
            {
                return GetSchoolFromArmor(inv.GetItemName(armor), inv.GetItemName(gloves), inv.GetItemName(pants), inv.GetItemName(boots), school);
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
                if (!chestplate_mode)
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

        if (!enabled || !GetEquippedSchool(school))
        {
            RestoreVanillaScabbards();
            return;
        }

        UpdateSteelScabbard(school);
        UpdateSilverScabbard(school);
    }
}

@addField(CR4Player)
public var ds : DynamicScabbards;

@addMethod(CR4Player)
public function InitDynamicScabbards()
{
    var currentVersion: string = "3.00";
    var currentVersionFloat: float = 3.00;

    var enabledValue: string;
    var chestModeValue: string;

    var inGameConfig: CInGameConfigWrapper;

    this.ds = new DynamicScabbards in this;
    inGameConfig = theGame.GetInGameConfigWrapper();
    
    if (!inGameConfig.GetVarValue('DSOptions', 'DSVersion'))
    {
        inGameConfig.SetVarValue('DSOptions', 'DSEnabled', true);
        inGameConfig.SetVarValue('DSOptions', 'DSModeChestplate', false);
        inGameConfig.SetVarValue('DSOptions', 'DSVersion', currentVersion);
        theGame.SaveUserSettings();
    }
    else if (StringToFloat(inGameConfig.GetVarValue('DSOptions', 'DSVersion')) < currentVersionFloat)
    {
        inGameConfig.SetVarValue('DSOptions', 'DSVersion', currentVersion);
        theGame.SaveUserSettings();
    }
    
    // Load settings with fallbacks for missing XML
    enabledValue = inGameConfig.GetVarValue('DSOptions', 'DSEnabled');
    chestModeValue = inGameConfig.GetVarValue('DSOptions', 'DSModeChestplate');
    
    if (enabledValue != "")
    {
        this.ds.SetEnabled(enabledValue);
    }
    else
    {
        this.ds.SetEnabled(true); // missing xml defaults to enabling the mod
    }
    
    if (chestModeValue != "")
    {
        this.ds.SetChestplateMode(chestModeValue);
    }
    else
    {
        this.ds.SetChestplateMode(false); // missing xml defaults to chestplate mode to be disabled
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

    if (!result)
    {
        return result;
    }

    thePlayer.GetDynamicScabbards().OnEquipmentChanged(slot);

    return result;
}

// update the menu swf for chestplate armor piece only setting. Disabling the options to interact with the menu when the mod is turned off prevents race conditions and exceptions
@addMethod(CR4IngameMenu)
function UpdateChestplateModeOption(disabled : bool)
{
    var dataArray : CScriptedFlashArray;
    var dataObject : CScriptedFlashObject;
    
    dataArray = m_flashValueStorage.CreateTempFlashArray();
    dataObject = m_flashValueStorage.CreateTempFlashObject();

    dataObject.SetMemberFlashUInt('tag', NameToFlashUInt('DSModeChestplate'));
    dataObject.SetMemberFlashBool('disabled', disabled);

    dataArray.PushBackFlashObject(dataObject);

    m_flashValueStorage.SetFlashArray('options.update_disabled', dataArray);
}

@wrapMethod(CR4IngameMenu)
function OnOptionValueChanged(groupId : int, optionName : name, optionValue : string)
{
    var result : bool;
    var groupName : name;
    var inGameConfig: CInGameConfigWrapper;
    var modEnabled: bool;
    var scabbards : DynamicScabbards;

    result = wrappedMethod(groupId, optionName, optionValue);

    if(result)
    {
       return result; 
    }

    inGameConfig = theGame.GetInGameConfigWrapper();
    groupName = inGameConfig.GetGroupName(groupId);

    if(groupName != 'DSOptions')
    {
        return result;
    }

    scabbards = thePlayer.GetDynamicScabbards();

    switch(optionName)
    {
        case 'DSEnabled':
            modEnabled = inGameConfig.GetVarValue(groupName, 'DSEnabled');

            scabbards.SetEnabled(modEnabled);
            scabbards.SetScabbards();
            UpdateChestplateModeOption(!modEnabled);

            break;
            
        case 'DSModeChestplate':
            scabbards.SetChestplateMode(inGameConfig.GetVarValue(groupName, 'DSModeChestplate'));
            scabbards.SetScabbards();
            break;
    }

    return result;
}

// disable the option to change chestplate armor piece settings when the mod is turned off in settings (before changing any value)
@wrapMethod(CR4IngameMenu)
function OnShowOptionSubmenu(actionType : int, menuTag : int, id : string)
{
    var result: bool;
    var inGameConfig: CInGameConfigWrapper;
    var modEnabled : bool;

    result = wrappedMethod(actionType, menuTag, id);

    if (id == "DS_settings")
    {
        inGameConfig = theGame.GetInGameConfigWrapper();
        modEnabled = inGameConfig.GetVarValue('DSOptions', 'DSEnabled');

        if (!modEnabled)
        {
            UpdateChestplateModeOption(true);
        }
    }

    return result;
}
