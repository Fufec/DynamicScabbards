// WPIAO keeps its outfit slots protected, so the two readers live in its class
@addMethod(WPIAO_OutfitManagerBase)
public function DS_HasOutfitOnSlot(slot : EEquipmentSlots) : bool
{
    return OutfitSlotExists(slot) && outfitSlots[slot].isOn;
}

// false for an empty outfit: the slot looks empty
@addMethod(WPIAO_OutfitManagerBase)
public function DS_GetOutfitItemName(slot : EEquipmentSlots, out item_name : name) : bool
{
    if (IsPreviewItemDefaultItem(slot))
    {
        return false;
    }

    item_name = outfitSlots[slot].previewItemName;
    return true;
}

// Dynamic Scabbards reads the item shown on each armor slot through GetVisibleItemName;
// with an outfit on the slot the outfit item counts
@wrapMethod(DynamicScabbards)
function GetVisibleItemName(slot : EEquipmentSlots, out item_name : name) : bool
{
    var manager : WPIAO_PreviewOutfitManager;

    manager = GetWitcherPlayer().ModWPIAO_GetManager();

    // no WPIAO or no outfit on this slot - the equipped item
    if (!manager || !manager.DS_HasOutfitOnSlot(slot))
    {
        return wrappedMethod(slot, item_name);
    }

    return manager.DS_GetOutfitItemName(slot, item_name);
}

// every way WPIAO changes an outfit
@wrapMethod(WPIAO_PreviewOutfitManager)
function SetOutfitByItem(item : SItemUniqueId) : bool
{
    var result : bool;
    result = wrappedMethod(item);

    if (result)
    {
        thePlayer.GetDynamicScabbards().SetScabbards();
    }

    return result;
}

@wrapMethod(WPIAO_PreviewOutfitManager)
function SetOutfitByDefaultItem(slot : EEquipmentSlots) : bool
{
    var result : bool;
    result = wrappedMethod(slot);

    if (result)
    {
        thePlayer.GetDynamicScabbards().SetScabbards();
    }

    return result;
}

@wrapMethod(WPIAO_PreviewOutfitManager)
function SetOutfitByOutfitSetItem(setItem : ModWPIAO_SOutfitSetItem) : bool
{
    var result : bool;
    result = wrappedMethod(setItem);

    if (result)
    {
        thePlayer.GetDynamicScabbards().SetScabbards();
    }

    return result;
}

@wrapMethod(WPIAO_PreviewOutfitManager)
function UnSetOutfitItem(slot : EEquipmentSlots, optional removeFromSet : bool) : bool
{
    var result : bool;
    result = wrappedMethod(slot, removeFromSet);

    if (result)
    {
        thePlayer.GetDynamicScabbards().SetScabbards();
    }

    return result;
}
