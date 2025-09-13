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
    // used as cache for holding the current values for unloading the templates when the player no longer has full set
    var current_steel_template : CEntityTemplate;
    var current_silver_template : CEntityTemplate;

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
            case 'Ofir Sabre 1':
            case 'Crafted Ofir Steel Sword':
            case 'Knights steel sword 3':
            case 'Olgierd Sabre':
            case 'Steel Vixen':
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
                return true;
        }

        return false;
    }

    function IncludeNewScabbardTemplate(scabbard : CEntityTemplate)
    {
        var component : CComponent;
        component = thePlayer.GetComponentByClassName('CAppearanceComponent');
        
        ((CAppearanceComponent)component).IncludeAppearanceTemplate(scabbard);	
    }

    function ExcludeOldScabbardTemplate(scabbard : CEntityTemplate)
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
            default:                        return "";
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
            default:                        return "";
        }
    }

    function SetSteelScabbard(sword_steel : SItemUniqueId, school: DSSchoolSet)
    {
        if(!thePlayer.GetInventory().IsItemSteelSwordUsableByPlayer(sword_steel)) 
        {
            return;
        }

        if (IsSteelException(sword_steel))
        {
            return;
        }

        if(current_steel_template)
        {
            ExcludeOldScabbardTemplate(current_steel_template);
        }

        current_steel_template = CreateTemplate(GetSteelScabbardPath(school));
        IncludeNewScabbardTemplate(current_steel_template);

        thePlayer.AddTimer('HideSteelScabbard', 0.01, false);
    }

    function SetSilverScabbard(sword_silver : SItemUniqueId, school: DSSchoolSet)
    {
        if(!thePlayer.GetInventory().IsItemSilverSwordUsableByPlayer(sword_silver)) 
        {
            return;
        }

        if (IsSilverException(sword_silver))
        {
            return;
        }

        if (current_silver_template)
        {   
            ExcludeOldScabbardTemplate(current_silver_template);
        }

        current_silver_template = CreateTemplate(GetSilverScabbardPath(school));
        IncludeNewScabbardTemplate(current_silver_template);

        thePlayer.AddTimer('HideSilverScabbard', 0.01, false);
    }

    function ClearSteelScabbard()
    {
        ExcludeOldScabbardTemplate(current_steel_template);
        HideScabbards('steel_scabbards', false);
        current_steel_template = NULL;
    }

    function ClearSilverScabbard()
    {
        ExcludeOldScabbardTemplate(current_silver_template);
        HideScabbards('silver_scabbards', false);
        current_silver_template = NULL;
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

    function CheckSingleSet(armor : name, gloves : name, pants : name, boots : name, schoolStr: string) : bool
    {
        if (StrContains(armor, schoolStr) && 
            StrContains(gloves, schoolStr) && 
            StrContains(pants, schoolStr) && 
            StrContains(boots, schoolStr))
        {
            return true;
        }

        return false;
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

        if (witcher.GetItemEquippedOnSlot(EES_Armor, armor)   && 
            witcher.GetItemEquippedOnSlot(EES_Gloves, gloves) && 
            witcher.GetItemEquippedOnSlot(EES_Pants, pants)   && 
            witcher.GetItemEquippedOnSlot(EES_Boots, boots))
        {
            return CheckWitcherSets(inv.GetItemName(armor), inv.GetItemName(gloves), inv.GetItemName(pants), inv.GetItemName(boots), school);
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

    public function SetScabbards(optional slot : EEquipmentSlots)
    {   
        var school : DSSchoolSet;

        if (!CheckEquippedArmor(school))
        {
            if (current_steel_template)
            {
                ClearSteelScabbard();
            }

            if (current_silver_template)
            {
                ClearSilverScabbard();
            }

            return;
        }

        if (slot == EES_SteelSword)
        {
            UpdateSteelScabbard(school);
        }
        else if (slot == EES_SilverSword)
        {
            UpdateSilverScabbard(school);
        }
        else // slot defaults to EES_InvalidSlot
        {
            UpdateSteelScabbard(school);
            UpdateSilverScabbard(school);
        }
    }

    public function ClearTemplateCacheAfterLoad()
    {
        current_steel_template = NULL;
        current_silver_template = NULL;
    }
}

@addField(CR4Player)
public var ds : DynamicScabbards;

@addMethod(CR4Player)
public function InitDS()
{
    this.ds = new DynamicScabbards in this;
}

// we need timer functions to delay the call to hide vanilla scabbards, otherwise the entity it will try to target won't be loaded yet
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

@wrapMethod(CR4Game)
function OnAfterLoadingScreenGameStart()
{
    wrappedMethod();

    if (!thePlayer.ds) 
    {
        thePlayer.InitDS();
    }

    thePlayer.ds.ClearTemplateCacheAfterLoad();
    thePlayer.ds.SetScabbards();
}

@wrapMethod(W3PlayerWitcher)
function EquipItemInGivenSlot(item : SItemUniqueId, slot : EEquipmentSlots, ignoreMounting : bool, optional toHand : bool) : bool
{
    var result : bool;

    result = wrappedMethod(item, slot, ignoreMounting, toHand);

    if (!thePlayer.ds)
    {
       thePlayer.InitDS();
    }

    if (slot == EES_SteelSword  ||
        slot == EES_SilverSword ||
        slot == EES_Armor       ||
        slot == EES_Boots       ||
        slot == EES_Pants       ||
        slot == EES_Gloves)
    {
        thePlayer.ds.SetScabbards(slot);
    }

    return result;
}

@wrapMethod(W3PlayerWitcher)
function UnequipItemFromSlot(slot : EEquipmentSlots, optional reequipped : bool) : bool
{
    var result : bool;

    result = wrappedMethod(slot, reequipped);

    if (!thePlayer.ds)
    {
       thePlayer.InitDS();
    }

    if (slot == EES_SteelSword  ||
        slot == EES_SilverSword ||
        slot == EES_Armor       ||
        slot == EES_Boots       ||
        slot == EES_Pants       ||
        slot == EES_Gloves)
    {
        thePlayer.ds.SetScabbards(slot);
    }

    return result;
}