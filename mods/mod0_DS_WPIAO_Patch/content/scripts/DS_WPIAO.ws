@addMethod(WPIAO_OutfitManagerBase)
public function DS_HasOutfitOnSlot(slot : EEquipmentSlots) : bool
{
    return OutfitSlotExists(slot) && outfitSlots[slot].isOn;
}

@addMethod(WPIAO_OutfitManagerBase)
public function DS_IsSlotEmptyOutfit(slot : EEquipmentSlots) : bool
{
    return DS_HasOutfitOnSlot(slot) && IsPreviewItemDefaultItem(slot);
}

@addMethod(WPIAO_OutfitManagerBase)
public function DS_GetVisibleItemName(slot : EEquipmentSlots, out itemName : name) : bool
{
    var tempId : SItemUniqueId;

    // WPIAO outfit is active on this slot - use the visual item name
    // (empty outfits are already filtered out by DS_IsSlotEmptyOutfit in CheckEquippedArmor)
    if (DS_HasOutfitOnSlot(slot))
    {
        itemName = outfitSlots[slot].previewItemName;
        return true;
    }

    // no WPIAO outfit on this slot - fall back to actually equipped item
    if (GetWitcherPlayer().GetItemEquippedOnSlot(slot, tempId))
    {
        itemName = thePlayer.GetInventory().GetItemName(tempId);
        return true;
    }

    // nothing equipped at all
    return false;
}

@wrapMethod(DynamicScabbards)
function CheckEquippedArmor(out school : DSSchoolSet) : bool
{
    var manager : WPIAO_PreviewOutfitManager;
    var armorName, glovesName, pantsName, bootsName : name;

    manager = GetWitcherPlayer().ModWPIAO_GetManager();

    // no WPIAO or no outfit on any armor slot - use default DS behavior
    if (!manager || (!manager.DS_HasOutfitOnSlot(EES_Armor)
                    && !manager.DS_HasOutfitOnSlot(EES_Gloves)
                    && !manager.DS_HasOutfitOnSlot(EES_Pants)
                    && !manager.DS_HasOutfitOnSlot(EES_Boots)))
    {
        return wrappedMethod(school);
    }

    // empty outfit on armor - never a school set regardless of mode
    if (manager.DS_IsSlotEmptyOutfit(EES_Armor))
    {
        return false;
    }

    if (chestplate_mode)
    {
        if (manager.DS_GetVisibleItemName(EES_Armor, armorName))
        {
            return CheckWitcherSets(armorName, '', '', '', school);
        }
    }
    else
    {
        // full set mode - any empty slot means no school scabbards
        if (manager.DS_IsSlotEmptyOutfit(EES_Gloves)
            || manager.DS_IsSlotEmptyOutfit(EES_Pants)
            || manager.DS_IsSlotEmptyOutfit(EES_Boots))
        {
            return false;
        }

        if (manager.DS_GetVisibleItemName(EES_Armor, armorName)
            && manager.DS_GetVisibleItemName(EES_Gloves, glovesName)
            && manager.DS_GetVisibleItemName(EES_Pants, pantsName)
            && manager.DS_GetVisibleItemName(EES_Boots, bootsName))
        {
            return CheckWitcherSets(armorName, glovesName, pantsName, bootsName, school);
        }
    }

    return false;
}

@wrapMethod(WPIAO_PreviewOutfitManager)
function SetOutfitByItem(item : SItemUniqueId) : bool
{
    var result : bool;
    result = wrappedMethod(item);

    if (result && thePlayer.EnsureDSInitializedAndEnabled())
    {
        thePlayer.ds.SetPendingUpdate(true);
    }

    return result;
}

@wrapMethod(WPIAO_PreviewOutfitManager)
function SetOutfitByDefaultItem(slot : EEquipmentSlots) : bool
{
    var result : bool;
    result = wrappedMethod(slot);

    if (result && thePlayer.EnsureDSInitializedAndEnabled())
    {
        thePlayer.ds.SetPendingUpdate(true);
    }

    return result;
}

@wrapMethod(WPIAO_PreviewOutfitManager)
function SetOutfitByOutfitSetItem(setItem : ModWPIAO_SOutfitSetItem) : bool
{
    var result : bool;
    result = wrappedMethod(setItem);

    if (result && thePlayer.EnsureDSInitializedAndEnabled())
    {
        thePlayer.ds.SetPendingUpdate(true);
    }

    return result;
}

@wrapMethod(WPIAO_PreviewOutfitManager)
function UnSetOutfitItem(slot : EEquipmentSlots, optional removeFromSet : bool) : bool
{
    var result : bool;
    result = wrappedMethod(slot, removeFromSet);

    if (result && thePlayer.EnsureDSInitializedAndEnabled())
    {
        thePlayer.ds.SetPendingUpdate(true);
    }

    return result;
}
