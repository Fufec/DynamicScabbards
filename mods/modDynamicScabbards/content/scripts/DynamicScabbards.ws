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

    // The scabbard definitions carry variants (mod bundle, gameplay\items\dynamic_scabbards.xml):
    // when the invisible item of a school is mounted, the engine spawns the bound scabbard of the
    // sword from the school template instead of its own. The script only keeps the right invisible
    // item mounted, one per category; the engine handles every draw, load, scene and fast travel
    public function GetSteelSchoolItemCategory() : name
    {
        return 'ds_steel';
    }

    public function GetSilverSchoolItemCategory() : name
    {
        return 'ds_silver';
    }

    // Some weapons do not match the regular scabbard size. We check for those and exclude them
    public function IsExcludedSteelSword(sword : SItemUniqueId) : bool
    {
        var current : name;
        current = thePlayer.GetInventory().GetItemName(sword);

        switch (current)
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

    public function IsExcludedSilverSword(sword : SItemUniqueId) : bool
    {
        var current : name;
        current = thePlayer.GetInventory().GetItemName(sword);

        switch (current)
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

    public function GetSteelSchoolItemName(school: DSSchoolSet) : name
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

    public function GetSilverSchoolItemName(school: DSSchoolSet) : name
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

    // keeps exactly one school item of the category mounted, '' means none. Returns false when the
    // item definition is missing (the bundle of the mod is not installed)
    function SetSchoolItem(category : name, item_name : name) : bool
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;

        if (IsSchoolItemMounted(category, item_name))
        {
            return true; // the usual case
        }

        RemoveSchoolItems(category);

        if (!IsNameValid(item_name))
        {
            return true;
        }

        inv = thePlayer.GetInventory();
        ids = inv.AddAnItem(item_name, 1, true, true);

        if (ids.Size() == 0)
        {
            return false;
        }

        inv.MountItem(ids[0]);
        return true;
    }

    public function UpdateSteelScabbard(school : DSSchoolSet)
    {
        var inv : CInventoryComponent;
        var sword_steel : SItemUniqueId;

        inv = thePlayer.GetInventory();

        if (!GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, sword_steel))
        {
            return; // no scabbard is mounted; the school item stays for the next sword
        }

        if (!inv.IsItemSteelSwordUsableByPlayer(sword_steel) || IsExcludedSteelSword(sword_steel))
        {
            SetSchoolItem(GetSteelSchoolItemCategory(), '');
            return;
        }

        SetSchoolItem(GetSteelSchoolItemCategory(), GetSteelSchoolItemName(school));
    }

    public function UpdateSilverScabbard(school : DSSchoolSet)
    {
        var inv : CInventoryComponent;
        var sword_silver : SItemUniqueId;

        inv = thePlayer.GetInventory();

        if (!GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, sword_silver))
        {
            return; // no scabbard is mounted; the school item stays for the next sword
        }

        if (!inv.IsItemSilverSwordUsableByPlayer(sword_silver) || IsExcludedSilverSword(sword_silver))
        {
            SetSchoolItem(GetSilverSchoolItemCategory(), '');
            return;
        }

        SetSchoolItem(GetSilverSchoolItemCategory(), GetSilverSchoolItemName(school));
    }

    // without a school item the bound scabbards spawn from their own templates
    public function RestoreVanillaScabbards()
    {
        SetSchoolItem(GetSteelSchoolItemCategory(), '');
        SetSchoolItem(GetSilverSchoolItemCategory(), '');
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

// creates the mod instance if needed and returns whether the mod is enabled
@addMethod(CR4Player)
function IsDynamicScabbardsEnabled() : bool
{
    if (!ds)
    {
       InitDynamicScabbards();
    }

    if(!ds.IsEnabled())
    {
        return false;
    }
    
    return true;
}

// once after every load: the school item is in the save and stays mounted, so this normally finds
// nothing to do; it matters when the mod is installed on an existing save or was updated
@wrapMethod(CR4Game)
function OnAfterLoadingScreenGameStart()
{
    wrappedMethod();

    if (thePlayer.IsDynamicScabbardsEnabled())
    {
        thePlayer.ds.SetScabbards();
    }
}

// the player changed (to Ciri and back): Geralt comes back with his inventory and the school item
// still mounted. This matters only when the mod was installed or updated while playing as Ciri
@wrapMethod(CR4Game)
function OnPlayerChanged()
{
    wrappedMethod();

    if (thePlayer.IsDynamicScabbardsEnabled())
    {
        thePlayer.ds.SetScabbards();
    }
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

    // also inside the inventory: the paperdoll shows mounted items, so the school scabbard follows
    // the equipped sword and armor right away. Cheap: usually the right item is already mounted
    if (thePlayer.IsDynamicScabbardsEnabled())
    {
        thePlayer.ds.SetScabbards();
    }

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

    // also inside the inventory: the paperdoll shows mounted items, so the school scabbard follows
    // the equipped sword and armor right away. Cheap: usually the right item is already mounted
    if (thePlayer.IsDynamicScabbardsEnabled())
    {
        thePlayer.ds.SetScabbards();
    }

    return result;
}

// update the menu sfw for chestplate armor piece only setting. Disabling the options to interact with the menu when the mod is turned off prevents race conditions and exceptions
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

    if (!thePlayer.ds)
    {
       thePlayer.InitDynamicScabbards();
    }

    switch(optionName)
    {
        case 'DSEnabled':
            modEnabled = inGameConfig.GetVarValue(groupName, 'DSEnabled');

            thePlayer.ds.SetEnabled(modEnabled);
            thePlayer.ds.SetScabbards();
            UpdateChestplateModeOption(!modEnabled);

            break;
            
        case 'DSModeChestplate':
            thePlayer.ds.SetChestplateMode(inGameConfig.GetVarValue(groupName, 'DSModeChestplate'));
            thePlayer.ds.SetScabbards();
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
