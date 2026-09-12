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

// WPIAO wraps the same equip functions as Dynamic Scabbards and turns the outfit of the slot off before
// the change and on again at the very end; the mod's own hook runs in between and sees the outfit off,
// so decide again once WPIAO is done
@wrapMethod(WPIAO_PreviewOutfitManager)
function PostWitcherEquip(result : bool, item : SItemUniqueId, slot : EEquipmentSlots, ignoreMounting : bool, optional toHand : bool) : bool
{
    var equipped : bool;

    equipped = wrappedMethod(result, item, slot, ignoreMounting, toHand);

    if (equipped)
    {
        thePlayer.GetDynamicScabbards().OnEquipmentChanged(slot);
    }

    return equipped;
}

@wrapMethod(WPIAO_PreviewOutfitManager)
function PostWitcherUnEquip(result : bool, item : SItemUniqueId, slot : EEquipmentSlots, optional reequipped : bool) : bool
{
    var unequipped : bool;

    unequipped = wrappedMethod(result, item, slot, reequipped);

    if (unequipped)
    {
        thePlayer.GetDynamicScabbards().OnEquipmentChanged(slot);
    }

    return unequipped;
}
