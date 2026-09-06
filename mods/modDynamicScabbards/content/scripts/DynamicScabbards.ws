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

    var update_pending : bool; // true if a sword or an armor has been changed/unequipped
    default update_pending = false;

    var unmounted_vanilla_steel : SItemUniqueId;
    var unmounted_vanilla_silver : SItemUniqueId;

    public function SetEnabled(value : bool) 
    { 
        enabled = value; 
    }

    public function SetChestplateMode(value : bool) 
    { 
        chestplate_mode = value; 
    }

    public function SetPendingUpdate(value: bool)
    {
        update_pending = value;
    }

    public function IsEnabled() : bool 
    { 
        return enabled; 
    }

    public function IsPendingUpdate() : bool
    {
        return update_pending;
    }

    // Tag custom scabbard items created by this mod
    public function GetDynamicScabbardTag() : name
    {
        return 'DynamicScabbard';
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

    public function GetSteelScabbardItemName(school: DSSchoolSet) : name
    {
        switch (school)
        {
            case DS_Set_KaerMorhen:        return 'scabbard_steel_1_01';
            case DS_Set_Bear:              return 'scabbard_steel_bear_01';
            case DS_Set_Cat:               return 'scabbard_steel_lynx_01';
            case DS_Set_Griffin:           return 'scabbard_steel_gryphon_01';
            case DS_Set_Manticore:
            case DS_Set_Wolf:              return 'scabbard_steel_wolf_01';
            case DS_Set_Viper:             return 'scabbard_steel_1_02';
            case DS_Set_ForgottenWolf:     return 'scabbard_steel_netflix_01';
            default:                       return '';
        }
    }

    public function GetSilverScabbardItemName(school: DSSchoolSet) : name
    {
        switch (school)
        {
            case DS_Set_KaerMorhen:        return 'scabbard_silver_1_01';
            case DS_Set_Bear:              return 'scabbard_silver_bear_01';
            case DS_Set_Cat:               return 'scabbard_silver_lynx_01';
            case DS_Set_Griffin:           return 'scabbard_silver_gryphon_01';
            case DS_Set_Manticore:
            case DS_Set_Wolf:              return 'scabbard_silver_wolf_01';
            case DS_Set_Viper:             return 'scabbard_silver_1_05';
            case DS_Set_ForgottenWolf:     return 'scabbard_silver_netflix_01';
            default:                       return '';
        }
    }

    // the tag tells a dynamic scabbard apart from a vanilla one with the same name (a wolf sword
    // binds the same scabbard_steel_wolf_01), the name tells the school
    function FindDynamicScabbard(category : name, item_name : name) : SItemUniqueId
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;
        var i : int;

        inv = thePlayer.GetInventory();
        ids = inv.GetItemsByCategory(category);

        for (i = 0; i < ids.Size(); i += 1)
        {
            if (inv.ItemHasTag(ids[i], GetDynamicScabbardTag()) && inv.GetItemName(ids[i]) == item_name)
            {
                return ids[i];
            }
        }

        return GetInvalidUniqueId();
    }

    // vanilla scabbards are never removed, only the ones this mod added
    function RemoveDynamicScabbards(category : name)
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;
        var i : int;

        inv = thePlayer.GetInventory();
        ids = inv.GetItemsByCategory(category);

        for (i = 0; i < ids.Size(); i += 1)
        {
            if (!inv.ItemHasTag(ids[i], GetDynamicScabbardTag()))
            {
                continue;
            }

            if (inv.IsItemMounted(ids[i]))
            {
                inv.UnmountItem(ids[i], true);
            }

            inv.RemoveItem(ids[i], 1);
        }
    }

    // an existing scabbard is reused so it does not blink on every update;
    // a scabbard of another school is replaced
    function MountDynamicScabbard(category : name, item_name : name) : bool
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;
        var dynamic_scabbard_id : SItemUniqueId;

        inv = thePlayer.GetInventory();
        dynamic_scabbard_id = FindDynamicScabbard(category, item_name);

        if (!inv.IsIdValid(dynamic_scabbard_id))
        {
            RemoveDynamicScabbards(category);
            ids = inv.AddAnItem(item_name, 1, true, true);

            if (ids.Size() == 0)
            {
                return false; // item definition missing (e.g. dlc10 not installed)
            }

            dynamic_scabbard_id = ids[0];
            inv.AddItemTag(dynamic_scabbard_id, GetDynamicScabbardTag());
        }

        if (!inv.IsItemMounted(dynamic_scabbard_id))
        {
            inv.MountItem(dynamic_scabbard_id);
        }

        return true;
    }

    // the engine mounts only the bound scabbard of the equipped sword, so there is at most one
    function FindMountedVanillaScabbard(category : name) : SItemUniqueId
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;
        var i : int;

        inv = thePlayer.GetInventory();
        ids = inv.GetItemsByCategory(category);

        for (i = 0; i < ids.Size(); i += 1)
        {
            if (!inv.ItemHasTag(ids[i], GetDynamicScabbardTag()) && inv.IsItemMounted(ids[i]))
            {
                return ids[i];
            }
        }

        return GetInvalidUniqueId();
    }

    function LoadSteelScabbard(sword_steel : SItemUniqueId, school : DSSchoolSet)
    {
        var inv : CInventoryComponent;
        var scabbard_name : name;
        var vanilla_scabbard_id : SItemUniqueId;

        inv = thePlayer.GetInventory();

        if (!inv.IsItemSteelSwordUsableByPlayer(sword_steel) || IsExcludedSteelSword(sword_steel))
        {
            RestoreVanillaSteelScabbard();
            return;
        }

        scabbard_name = GetSteelScabbardItemName(school);

        vanilla_scabbard_id = FindMountedVanillaScabbard('steel_scabbards');
        if (inv.IsIdValid(vanilla_scabbard_id))
        {
            // unmounting destroys the entity on Geralt's back but keeps the item in the inventory,
            // so it can be mounted again when the mod lets go of the category
            inv.UnmountItem(vanilla_scabbard_id, true);
            unmounted_vanilla_steel = vanilla_scabbard_id;
        }

        if (!MountDynamicScabbard('steel_scabbards', scabbard_name))
        {
            RestoreVanillaSteelScabbard();
        }
    }

    public function UnloadSteelScabbard()
    {
        RemoveDynamicScabbards('steel_scabbards');
        unmounted_vanilla_steel = GetInvalidUniqueId();
    }

    public function RestoreVanillaSteelScabbard()
    {
        var inv : CInventoryComponent;
        var vanilla_scabbard_id : SItemUniqueId;
        var sword_steel : SItemUniqueId;

        inv = thePlayer.GetInventory();
        vanilla_scabbard_id = unmounted_vanilla_steel;
        UnloadSteelScabbard();

        if (!GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, sword_steel))
        {
            return;
        }

        // the engine may have mounted a vanilla scabbard on its own (e.g. for an excluded sword)
        if (inv.IsIdValid(FindMountedVanillaScabbard('steel_scabbards')))
        {
            return;
        }

        if (inv.IsIdValid(vanilla_scabbard_id))
        {
            inv.MountItem(vanilla_scabbard_id);
        }
    }

    public function UpdateSteelScabbard(school : DSSchoolSet)
    {
        var sword_steel : SItemUniqueId;

        if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, sword_steel))
        {
            LoadSteelScabbard(sword_steel, school);
        }
        else
        {
            UnloadSteelScabbard();
        }
    }

    function LoadSilverScabbard(sword_silver : SItemUniqueId, school : DSSchoolSet)
    {
        var inv : CInventoryComponent;
        var scabbard_name : name;
        var vanilla_scabbard_id : SItemUniqueId;

        inv = thePlayer.GetInventory();

        if (!inv.IsItemSilverSwordUsableByPlayer(sword_silver) || IsExcludedSilverSword(sword_silver))
        {
            RestoreVanillaSilverScabbard();
            return;
        }

        scabbard_name = GetSilverScabbardItemName(school);

        vanilla_scabbard_id = FindMountedVanillaScabbard('silver_scabbards');
        if (inv.IsIdValid(vanilla_scabbard_id))
        {
            // unmounting destroys the entity on Geralt's back but keeps the item in the inventory,
            // so it can be mounted again when the mod lets go of the category
            inv.UnmountItem(vanilla_scabbard_id, true);
            unmounted_vanilla_silver = vanilla_scabbard_id;
        }

        if (!MountDynamicScabbard('silver_scabbards', scabbard_name))
        {
            RestoreVanillaSilverScabbard();
        }
    }

    public function UnloadSilverScabbard()
    {
        RemoveDynamicScabbards('silver_scabbards');
        unmounted_vanilla_silver = GetInvalidUniqueId();
    }

    public function RestoreVanillaSilverScabbard()
    {
        var inv : CInventoryComponent;
        var vanilla_scabbard_id : SItemUniqueId;
        var sword_silver : SItemUniqueId;

        inv = thePlayer.GetInventory();
        vanilla_scabbard_id = unmounted_vanilla_silver;
        UnloadSilverScabbard();

        if (!GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, sword_silver))
        {
            return;
        }

        // the engine may have mounted a vanilla scabbard on its own (e.g. for an excluded sword)
        if (inv.IsIdValid(FindMountedVanillaScabbard('silver_scabbards')))
        {
            return;
        }

        if (inv.IsIdValid(vanilla_scabbard_id))
        {
            inv.MountItem(vanilla_scabbard_id);
        }
    }

    public function UpdateSilverScabbard(school : DSSchoolSet)
    {
        var sword_silver : SItemUniqueId;

        if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, sword_silver))
        {
            LoadSilverScabbard(sword_silver, school);
        }
        else
        {
            UnloadSilverScabbard();
        }
    }

    public function RestoreVanillaScabbards()
    {
        RestoreVanillaSteelScabbard();
        RestoreVanillaSilverScabbard();
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

    // Determine which slots trigger scabbard updates based on mode
    public function TriggersScabbardUpdate(slot : EEquipmentSlots) : bool
    {
        switch (slot)
        {
            case EES_SteelSword:
            case EES_SilverSword:
            case EES_Armor:
                return true;
            case EES_Boots:
            case EES_Pants:
            case EES_Gloves:
                // In chestplate mode, gloves/pants/boots don't trigger updates
                return !chestplate_mode;
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

@addMethod(CR4Player)
timer function SetScabbardsDelayed(dt : float, id : int)
{
    ds.SetScabbards();
}

@addMethod(CR4Player)
function HandleScabbardUpdate(slot : EEquipmentSlots)
{
    if (ds.TriggersScabbardUpdate(slot))
    {
        if(theGame.GetGuiManager().IsAnyMenu()) // we're in inventory, swap only after closing the inventory (handled by OnClosingMenu())
        {
            if (!ds.IsPendingUpdate())
            {
                ds.SetPendingUpdate(true);
            }
        }
        else // we're for example in cutscene or at barber, delay the call
        {
            AddTimer('SetScabbardsDelayed', 0.6, false); // note: 0.5 is too low for barber
        }
    }
}

// this covers Ciri swap and OnAfterLoadingScreenGameStart (e.g. Loading a save file, fast travelling etc.)
@wrapMethod(CActor)
function OnAppearanceChanged()
{
    var result : bool;

    result = wrappedMethod();

    if (this != thePlayer)
    {
        return result;
    }

    if (thePlayer.IsDynamicScabbardsEnabled())
    {
        thePlayer.AddTimer('SetScabbardsDelayed', 0.2, false); // note: 0.1 is too low after loading a game (or after ciri sequence)
    }

    return result;
}

/*
// after a cutscene the engine can mount the vanilla scabbard again
@wrapMethod(CR4Player)
function OnBlockingSceneEnded(optional output : CStorySceneOutput)
{
    var result : bool;

    result = wrappedMethod(output);

    if (this == thePlayer && IsDynamicScabbardsEnabled())
    {
        AddTimer('SetScabbardsDelayed', 0.5, false);
    }

    return result;
}
*/
@wrapMethod(W3PlayerWitcher)
function EquipItemInGivenSlot(item : SItemUniqueId, slot : EEquipmentSlots, ignoreMounting : bool, optional toHand : bool) : bool
{
    var result : bool;

    result = wrappedMethod(item, slot, ignoreMounting, toHand);

    if (!result)
    {
        return result;
    }

    if (thePlayer.IsDynamicScabbardsEnabled())
    {
        thePlayer.HandleScabbardUpdate(slot);
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

    if (thePlayer.IsDynamicScabbardsEnabled())
    {
        thePlayer.HandleScabbardUpdate(slot);
    }

    return result;
}

// handle pending update when returning from GUI menu
@wrapMethod(CR4CommonMenu)
function OnClosingMenu()
{
    var result: bool;

    result = wrappedMethod();

    if (thePlayer.IsDynamicScabbardsEnabled())
    {
        if (thePlayer.ds.IsPendingUpdate())
        {
            thePlayer.ds.SetScabbards();
            thePlayer.ds.SetPendingUpdate(false);
        }
    }

    return result;
}

// handle pending updates when returning from pause menu
@wrapMethod(CR4CommonIngameMenu)
function OnClosingMenu()
{
    var result: bool;

    result = wrappedMethod();

    if (thePlayer.IsDynamicScabbardsEnabled())
    {
        if (thePlayer.ds.IsPendingUpdate())
        {
            thePlayer.ds.SetScabbards();
            thePlayer.ds.SetPendingUpdate(false);
        }
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
            thePlayer.ds.SetPendingUpdate(true);
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
