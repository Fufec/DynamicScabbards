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

    // used as cache for holding the current values for unloading the templates when the player no longer has full set
    var current_steel_template : CEntityTemplate;
    var current_silver_template : CEntityTemplate;

    // timer delay for hiding/showing vanilla scabbards to ensure entity is loaded
    var scabbard_hide_delay : float;
    default scabbard_hide_delay = 0.01;

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

    // Some weapons do not match the regular scabbard size. We check for those and exclude them
    function IsSteelException(weapon: SItemUniqueId) : bool
    {
        var current : name;
        current = thePlayer.GetInventory().GetItemName(weapon);

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
                return true;
        }

        return false;
    }

    function IsSilverException(weapon: SItemUniqueId) : bool
    {
        var current : name;
        current = thePlayer.GetInventory().GetItemName(weapon);

        switch (current)
        {
            case 'Silver Vixen':
            case 'Netflix silver sword':
            case 'Netflix silver sword 1':
            case 'Netflix silver sword 2':
                return true;
        }

        return false;
    }

    function IncludeScabbardTemplate(scabbard : CEntityTemplate)
    {
        var component : CComponent;
        component = thePlayer.GetComponentByClassName('CAppearanceComponent');
        
        ((CAppearanceComponent)component).IncludeAppearanceTemplate(scabbard);	
    }

    function ExcludeScabbardTemplate(scabbard : CEntityTemplate)
    {
        var component : CComponent;
        component = thePlayer.GetComponentByClassName('CAppearanceComponent');

        ((CAppearanceComponent)component).ExcludeAppearanceTemplate(scabbard);
    }

    function CreateTemplate(path : string) : CEntityTemplate
    {
        return (CEntityTemplate)LoadResource(path, true);
    }

    function GetSilverScabbardPath(school: DSSchoolSet) : string
    {
        switch (school)
        {
            case DS_Set_KaerMorhen:        return "items\bodyparts\geralt_items\scabbards\silver_scabbards\scabbard_silver_1_01.w2ent";
            case DS_Set_Bear:              return "items\weapons\swords\witcher_silver_scabbards\witcher_silver_bear_scabbard.w2ent";
            case DS_Set_Cat:               return "items\weapons\swords\witcher_silver_scabbards\witcher_silver_lynx_scabbard.w2ent";
            case DS_Set_Griffin:           return "items\weapons\swords\witcher_silver_scabbards\witcher_silver_gryphon_scabbard.w2ent";
            case DS_Set_Manticore:
            case DS_Set_Wolf:              return "dlc\dlc10\data\items\weapons\swords\witcher_silver_swords\witcher_silver_wolf_scabbard.w2ent";
            case DS_Set_Viper:             return "items\bodyparts\geralt_items\scabbards\silver_scabbards\scabbard_silver_1_05.w2ent";
            case DS_Set_ForgottenWolf:     return "items\weapons\swords\witcher_silver_scabbards\witcher_silver_netflix_scabbard.w2ent";
            default:                       return "";
        }
    }

    function GetSteelScabbardPath(school: DSSchoolSet) : string
    {
        switch (school)
        {
            case DS_Set_KaerMorhen:        return "items\bodyparts\geralt_items\scabbards\steel_scabbards\scabbard_steel_1_01.w2ent";
            case DS_Set_Bear:              return "items\weapons\swords\witcher_steel_scabbards\witcher_steel_bear_scabbard.w2ent";
            case DS_Set_Cat:               return "items\weapons\swords\witcher_steel_scabbards\witcher_steel_lynx_scabbard.w2ent";
            case DS_Set_Griffin:           return "items\weapons\swords\witcher_steel_scabbards\witcher_steel_gryphon_scabbard.w2ent";
            case DS_Set_Manticore:
            case DS_Set_Wolf:              return "dlc\dlc10\data\items\weapons\swords\witcher_steel_swords\witcher_steel_wolf_scabbard.w2ent";
            case DS_Set_Viper:             return "items\bodyparts\geralt_items\scabbards\steel_scabbards\scabbard_steel_1_02.w2ent";
            case DS_Set_ForgottenWolf:     return "items\weapons\swords\witcher_steel_scabbards\witcher_steel_netflix_scabbard.w2ent";
            default:                       return "";
        }
    }

    function SetSteelScabbard(sword_steel : SItemUniqueId, school: DSSchoolSet)
    {
        if(current_steel_template)
        {
            ExcludeScabbardTemplate(current_steel_template);
            current_steel_template = NULL;
        }

        if(!thePlayer.GetInventory().IsItemSteelSwordUsableByPlayer(sword_steel)) 
        {
            return;
        }

        if (IsSteelException(sword_steel))
        {
            return;
        }

        current_steel_template = CreateTemplate(GetSteelScabbardPath(school));
        IncludeScabbardTemplate(current_steel_template);

        thePlayer.AddTimer('HideSteelScabbard', scabbard_hide_delay, false);
    }

    function SetSilverScabbard(sword_silver : SItemUniqueId, school: DSSchoolSet)
    {
        if (current_silver_template)
        {   
            ExcludeScabbardTemplate(current_silver_template);
            current_silver_template = NULL;
        }

        if(!thePlayer.GetInventory().IsItemSilverSwordUsableByPlayer(sword_silver)) 
        {
            return;
        }

        if (IsSilverException(sword_silver))
        {
            return;
        }

        current_silver_template = CreateTemplate(GetSilverScabbardPath(school));
        IncludeScabbardTemplate(current_silver_template);

        thePlayer.AddTimer('HideSilverScabbard', scabbard_hide_delay, false);
    }

    function ClearSteelScabbard()
    {
        ExcludeScabbardTemplate(current_steel_template);
        thePlayer.AddTimer('ShowSteelScabbard', scabbard_hide_delay, false);
        current_steel_template = NULL;
    }

    function ClearSilverScabbard()
    {
        ExcludeScabbardTemplate(current_silver_template);
        thePlayer.AddTimer('ShowSilverScabbard', scabbard_hide_delay, false);
        current_silver_template = NULL;
    }

    function ClearScabbards()
    {
        if (current_steel_template)
        {
            ClearSteelScabbard();
        }

        if (current_silver_template)
        {
            ClearSilverScabbard();
        }
    }

    function UpdateSteelScabbard(school: DSSchoolSet)
    {
        var sword_steel : SItemUniqueId;

        if(GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, sword_steel))
        {
            SetSteelScabbard(sword_steel, school);
        }
        else
        {
            if (current_steel_template)
            {
                ClearSteelScabbard();
            }
        }
    }

    function UpdateSilverScabbard(school: DSSchoolSet)
    {
        var sword_silver : SItemUniqueId;

        if(GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, sword_silver))
        { 
            SetSilverScabbard(sword_silver, school);
        }
        else
        {
            if (current_silver_template)
            {
                ClearSilverScabbard();
            }
        }
    }

    // Set detection: full-set or chestplate-only mode based on chestplate_mode setting
    function CheckSingleSet(armor : name, gloves : name, pants : name, boots : name, schoolStr: string) : bool
    {
        if (chestplate_mode)
        {
            return StrContains(armor, schoolStr);
        }
        else
        {
            return (StrContains(armor, schoolStr) && 
                    StrContains(gloves, schoolStr) && 
                    StrContains(pants, schoolStr) && 
                    StrContains(boots, schoolStr));
        }
    }

    function CheckWitcherSets(armor : name, gloves : name, pants : name, boots : name, out school: DSSchoolSet) : bool
    {
        if (CheckSingleSet(armor, gloves, pants, boots, "Starting"))      { school = DS_Set_KaerMorhen;     return true;}
        if (CheckSingleSet(armor, gloves, pants, boots, "Bear"))          { school = DS_Set_Bear;           return true;}
        if (CheckSingleSet(armor, gloves, pants, boots, "Lynx"))          { school = DS_Set_Cat;            return true;}
        if (CheckSingleSet(armor, gloves, pants, boots, "Gryphon"))       { school = DS_Set_Griffin;        return true;}
        if (CheckSingleSet(armor, gloves, pants, boots, "Red Wolf"))      { school = DS_Set_Manticore;      return true;}
        if (CheckSingleSet(armor, gloves, pants, boots, "Wolf"))          { school = DS_Set_Wolf;           return true;}
        if (CheckSingleSet(armor, gloves, pants, boots, "EP1 Witcher"))   { school = DS_Set_Viper;          return true;}
        if (CheckSingleSet(armor, gloves, pants, boots, "Netflix"))       { school = DS_Set_ForgottenWolf;  return true;}

        // Built-in compatibility for Witcher School Set Rework and Balance mod
        if (CheckSingleSet(armor, gloves, pants, boots, "Kaer Morhen"))   { school = DS_Set_KaerMorhen;     return true;}
        if (CheckSingleSet(armor, gloves, pants, boots, "Viper"))         { school = DS_Set_Viper;          return true;}
        if (CheckSingleSet(armor, gloves, pants, boots, "Manticore"))     { school = DS_Set_Manticore;      return true;}

        return false;
    }

    function CheckEquippedArmor(out school: DSSchoolSet) : bool
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
                return CheckWitcherSets(inv.GetItemName(armor), '', '', '', school);
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
                return CheckWitcherSets(inv.GetItemName(armor), inv.GetItemName(gloves), inv.GetItemName(pants), inv.GetItemName(boots), school);
            }
        }
        
        return false;
    }

    public function HideScabbards(category : name, hide : bool)
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;
        var size : int;
        var i    : int;
        var entity  : CEntity;
        
        inv = thePlayer.GetInventory();
        ids = inv.GetItemsByCategory(category);
        size = ids.Size();

        if (size == 0)
        {
            return;
        }

        for (i = 0; i < size; i += 1)
        {
            entity = inv.GetItemEntityUnsafe(ids[i]);
            if (entity)
            {
                entity.SetHideInGame(hide);
            }
        }
    }

    // Determine which slots trigger scabbard updates based on mode
    public function IsSwordOrArmorSlot(slot : EEquipmentSlots) : bool
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

        if (!enabled)
        {
            ClearScabbards();
            return;
        }

        if (!CheckEquippedArmor(school))
        {
            ClearScabbards();
            return;
        }

        UpdateSteelScabbard(school);
        UpdateSilverScabbard(school);
    }
}

@addField(CR4Player)
public var ds : DynamicScabbards;

@addMethod(CR4Player)
public function InitDS()
{
    var currentVersion: string = "2.02";
    var currentVersionFloat: float = 2.02;

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

@addMethod(CR4Player)
function EnsureDSInitializedAndEnabled() : bool
{
    if (!ds)
    {
       InitDS();
    }

    if(!ds.IsEnabled())
    {
        return false;
    }
    
    return true;
}

// we need timer functions to delay the call to hide/show vanilla scabbards, otherwise the entity it will try to target won't be loaded yet
@addMethod(CR4Player)
timer function HideSteelScabbard(dt : float, id : int)
{
    ds.HideScabbards('steel_scabbards', true);
}

@addMethod(CR4Player)
timer function HideSilverScabbard(dt : float, id : int)
{
    ds.HideScabbards('silver_scabbards', true);
}

@addMethod(CR4Player)
timer function ShowSteelScabbard(dt : float, id : int)
{
    ds.HideScabbards('steel_scabbards', false);
}

@addMethod(CR4Player)
timer function ShowSilverScabbard(dt : float, id : int)
{
    ds.HideScabbards('silver_scabbards', false);
}

@addMethod(CR4Player)
timer function SetScabbardsDelayed(dt : float, id : int)
{
    ds.SetScabbards();
}

@addMethod(CR4Player)
function HandleScabbardUpdate(slot : EEquipmentSlots)
{
    if (ds.IsSwordOrArmorSlot(slot))
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

    if (thePlayer.EnsureDSInitializedAndEnabled())
    {
        thePlayer.AddTimer('SetScabbardsDelayed', 0.15, false); // note: 0.1 is too low after loading a game (or after ciri sequence)
    }

    return result;
}

@wrapMethod(W3PlayerWitcher)
function EquipItemInGivenSlot(item : SItemUniqueId, slot : EEquipmentSlots, ignoreMounting : bool, optional toHand : bool) : bool
{
    var result : bool;

    result = wrappedMethod(item, slot, ignoreMounting, toHand);

    if (thePlayer.EnsureDSInitializedAndEnabled())
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

    if (thePlayer.EnsureDSInitializedAndEnabled())
    {
        thePlayer.HandleScabbardUpdate(slot);
    }

    return result;
}

@wrapMethod(CR4CommonMenu)
function OnClosingMenu()
{
    var result: bool;

    result = wrappedMethod();

    if (thePlayer.EnsureDSInitializedAndEnabled())
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
function UpdateDSChestplateSettings(disabled : bool)
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
       thePlayer.InitDS();
    }

    switch(optionName)
    {
        case 'DSEnabled':
            modEnabled = inGameConfig.GetVarValue(groupName, 'DSEnabled');

            thePlayer.ds.SetEnabled(modEnabled);
            thePlayer.ds.SetScabbards();
            UpdateDSChestplateSettings(!modEnabled);

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
            UpdateDSChestplateSettings(true);
        }
    }

    return result;
}