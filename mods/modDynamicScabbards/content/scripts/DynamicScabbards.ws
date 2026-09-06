// ============================================================================
// Dynamic Scabbards - EXPERIMENTAL item-swap branch
//
// The scabbard is swapped as an inventory ITEM, not as an appearance template:
//   - the vanilla scabbard bound to the equipped sword gets unmounted (never
//     deleted); DS remembers it so it can be re-mounted when DS lets go,
//   - a vanilla-defined school scabbard item (e.g. 'scabbard_steel_bear_01')
//     is added, tagged 'DS_Scabbard' and mounted.
// Because the mounted scabbard item now really is the school scabbard, any mod
// that reads the scabbard through the inventory (Swords and Meditation,
// Swords on Hip, Auto Hide Weapons, ...) picks up the correct entity without a patch.
//
// Verified engine behaviour this relies on:
//   - script-added scabbard items do not survive save/load; after a load the
//     sword's bound vanilla scabbard is mounted again and DS re-applies itself,
//   - on a sword swap the engine unmounts the DS scabbard and mounts the new
//     sword's bound one; DS reconciles afterwards,
//   - cutscenes can re-mount the sword (and its scabbard), hence the
//     OnBlockingSceneEnded hook.
// ============================================================================

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

    // vanilla scabbards unmounted by DS, re-mounted when DS lets go of the category (runtime only,
    // after a load the engine mounts them itself)
    var vanilla_steel : SItemUniqueId;
    var vanilla_silver : SItemUniqueId;

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
    public function IsSteelException(weapon: SItemUniqueId) : bool
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
            case 'Cleaver':
            case 'Dwarven sword 1':
            case 'Dwarven sword 1_crafted':
            case 'Dwarven sword 2':
            case 'Dwarven sword 2_crafted':
                return true;
        }

        return false;
    }

    public function IsSilverException(weapon: SItemUniqueId) : bool
    {
        var current : name;
        current = thePlayer.GetInventory().GetItemName(weapon);

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

    // Vanilla item definitions (category silver_scabbards / steel_scabbards):
    //   content0  _technical_items_defs.xml : scabbard_*_1_01, scabbard_*_1_02, scabbard_silver_1_05, scabbard_*_bear_01, scabbard_*_lynx_01, scabbard_*_gryphon_01
    //   dlc10     dlc10_wolf_swords.xml     : scabbard_*_wolf_01
    //   content0  dlc18_netflix_swords.xml  : scabbard_*_netflix_01
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

    // Tag marking scabbard items created by this mod. Vanilla (sword-bound) scabbards never carry it.
    public function GetDSItemTag() : name
    {
        return 'DS_Scabbard';
    }

    // Which scabbard item DS wants mounted for the sword in the given slot; '' means "leave vanilla"
    function GetScabbardToMount(slot : EEquipmentSlots, school : DSSchoolSet) : name
    {
        var inv : CInventoryComponent;
        var sword : SItemUniqueId;

        if (!GetWitcherPlayer().GetItemEquippedOnSlot(slot, sword))
        {
            return '';
        }

        inv = thePlayer.GetInventory();

        if (slot == EES_SteelSword)
        {
            if (!inv.IsItemSteelSwordUsableByPlayer(sword) || IsSteelException(sword))
            {
                return '';
            }
            return GetSteelScabbardItemName(school);
        }

        if (!inv.IsItemSilverSwordUsableByPlayer(sword) || IsSilverException(sword))
        {
            return '';
        }
        return GetSilverScabbardItemName(school);
    }

    function RememberVanilla(slot : EEquipmentSlots, item : SItemUniqueId)
    {
        if (slot == EES_SteelSword) { vanilla_steel = item; }
        else                        { vanilla_silver = item; }
    }

    function GetRememberedVanilla(slot : EEquipmentSlots) : SItemUniqueId
    {
        if (slot == EES_SteelSword) { return vanilla_steel; }
        return vanilla_silver;
    }

    function RemoveScabbard(inv : CInventoryComponent, item : SItemUniqueId)
    {
        if (inv.IsItemMounted(item))
        {
            inv.UnmountItem(item, true);
        }
        inv.RemoveItem(item, 1);
    }

    // Brings one scabbard category into the wanted state:
    //   scabbard_to_mount set  -> exactly one DS item of that name exists and is mounted, vanilla is unmounted
    //   scabbard_to_mount ''   -> no DS item; if a sword is equipped and nothing vanilla is mounted, re-mount the remembered vanilla
    function Reconcile(category : name, slot : EEquipmentSlots, scabbard_to_mount : name)
    {
        var inv : CInventoryComponent;
        var ids : array<SItemUniqueId>;
        var new_ids : array<SItemUniqueId>;
        var sword, ds_item, vanilla : SItemUniqueId;
        var has_sword, want_ds, ds_found, vanilla_mounted : bool;
        var i : int;

        inv = thePlayer.GetInventory();
        has_sword = GetWitcherPlayer().GetItemEquippedOnSlot(slot, sword);
        want_ds = IsNameValid(scabbard_to_mount);
        ids = inv.GetItemsByCategory(category);

        for (i = 0; i < ids.Size(); i += 1)
        {
            if (inv.ItemHasTag(ids[i], GetDSItemTag()))
            {
                if (want_ds && !ds_found && inv.GetItemName(ids[i]) == scabbard_to_mount)
                {
                    ds_found = true;
                    ds_item = ids[i];
                }
                else
                {
                    RemoveScabbard(inv, ids[i]);
                }
            }
            else if (inv.IsItemMounted(ids[i]))
            {
                if (want_ds)
                {
                    RememberVanilla(slot, ids[i]);
                    inv.UnmountItem(ids[i], true);
                }
                else
                {
                    vanilla_mounted = true;
                }
            }
        }

        if (want_ds)
        {
            if (!ds_found)
            {
                new_ids = inv.AddAnItem(scabbard_to_mount, 1, true, true);
                if (new_ids.Size() == 0)
                {
                    LogChannel('DynamicScabbards', "Failed to add scabbard item " + NameToString(scabbard_to_mount));
                    return;
                }
                ds_item = new_ids[0];
                inv.AddItemTag(ds_item, GetDSItemTag());
            }

            if (!inv.IsItemMounted(ds_item))
            {
                inv.MountItem(ds_item);
            }
            return;
        }

        // DS lets go of this category
        vanilla = GetRememberedVanilla(slot);
        RememberVanilla(slot, GetInvalidUniqueId());

        if (has_sword && !vanilla_mounted && inv.IsIdValid(vanilla))
        {
            inv.MountItem(vanilla);
        }
    }

    public function UnloadScabbardsAndRestoreVanilla()
    {
        Reconcile('steel_scabbards',  EES_SteelSword,  '');
        Reconcile('silver_scabbards', EES_SilverSword, '');
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

    public function CheckEquippedArmor(out school: DSSchoolSet) : bool
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

        // thePlayer is not Geralt (e.g. Ciri sequence) - the inventory we would touch is not his
        if (!GetWitcherPlayer())
        {
            return;
        }

        if (!enabled || !CheckEquippedArmor(school))
        {
            UnloadScabbardsAndRestoreVanilla();
            return;
        }

        Reconcile('steel_scabbards',  EES_SteelSword,  GetScabbardToMount(EES_SteelSword, school));
        Reconcile('silver_scabbards', EES_SilverSword, GetScabbardToMount(EES_SilverSword, school));
    }
}

@addField(CR4Player)
public var ds : DynamicScabbards;

@addMethod(CR4Player)
public function InitDS()
{
    var currentVersion: string = "2.22";
    var currentVersionFloat: float = 2.22;

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

@addMethod(CR4Player)
timer function SetScabbardsDelayed(dt : float, id : int)
{
    ds.SetScabbards();
}

@addMethod(CR4Player)
function HandleScabbardUpdate(item : SItemUniqueId, slot : EEquipmentSlots)
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
        thePlayer.AddTimer('SetScabbardsDelayed', 0.2, false); // note: 0.1 is too low after loading a game (or after ciri sequence). With DS_SOH patch, 0.15 is still too low
    }

    return result;
}

// cutscenes can re-mount the sword and with it its vanilla scabbard (e.g. after the Ciri sequence)
@wrapMethod(CR4Player)
function OnBlockingSceneEnded(optional output : CStorySceneOutput)
{
    var result : bool;

    result = wrappedMethod(output);

    if (this == thePlayer && EnsureDSInitializedAndEnabled())
    {
        AddTimer('SetScabbardsDelayed', 0.5, false);
    }

    return result;
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

    if (thePlayer.EnsureDSInitializedAndEnabled())
    {
        thePlayer.HandleScabbardUpdate(item, slot);
    }

    return result;
}

@wrapMethod(W3PlayerWitcher)
function UnequipItemFromSlot(slot : EEquipmentSlots, optional reequipped : bool) : bool
{
    var result : bool;
    var item : SItemUniqueId;

    GetItemEquippedOnSlot(slot, item);

    result = wrappedMethod(slot, reequipped);

    if (!result)
    {
        return result;
    }

    if (thePlayer.EnsureDSInitializedAndEnabled())
    {
        thePlayer.HandleScabbardUpdate(item, slot);
    }

    return result;
}

// handle pending update when returning from GUI menu
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

// handle pending updates when returning from pause menu
@wrapMethod(CR4CommonIngameMenu)
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
            UpdateDSChestplateSettings(true);
        }
    }

    return result;
}
