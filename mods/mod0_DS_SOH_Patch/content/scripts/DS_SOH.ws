@replaceMethod(W3InvisibleWeapons)
function Check_Steel_Carrrying()
{
    var swordsteel_temp         : CEntity;

    // mod0_DS_SOH_Patch START
    var scab_string             : string;
    var ds_school               : DSSchoolSet;
    // mod0_DS_SOH_Patch END
    
    if ( thePlayer.GetInventory().GetItemEquippedOnSlot(EES_SteelSword, steelid) )
    {
        swordsteel_temp = thePlayer.GetInventory().GetItemEntityUnsafe(steelid);
        steelcomp = (CDrawableComponent)((thePlayer.GetInventory().GetItemEntityUnsafe(steelid)).GetMeshComponent());
        //swordst = (CWitcherSword)thePlayer.GetInventory().GetItemEntityUnsafe( steelid );
    }
    else 
    { 
        if ( steelcopy )
        {
            steelcopy.Destroy(); 
        }
        if ( steelcopycopy )
        {
            steelcopycopy.Destroy(); 
        }
        if ( steel_dummy )
        {
            steel_dummy.Destroy(); 
        }
        if ( steelscabcopy )
        {
            steelscabcopy.Destroy(); 
        }
        if ( scabsteelcomp )
        {
            scabsteelcomp = NULL; 
        }
        if ( steelcopycomp )
        {
            steelcopycomp = NULL; 
        }
    }
    
    if ( swordsteel.GetReadableName() != swordsteel_temp.GetReadableName() )
    {
        //theGame.witcherLog.AddMessage("swordsteel.GetReadableName() != swordsteel_temp.GetReadableName()"); 
        swordsteel = swordsteel_temp;
    
        if ( steelcopy )
        {
            steelcopy.Destroy(); 
        }
        if ( steelcopycopy )
        {
            steelcopycopy.Destroy(); 
        }
        if ( steel_dummy )
        {
            steel_dummy.Destroy(); 
        }
        if ( steelscabcopy )
        {
            steelscabcopy.Destroy(); 
        }
        if ( scabsteelcomp )
        {
            scabsteelcomp = NULL; 
        }
        if ( steelcopycomp )
        {
            steelcopycomp = NULL; 
        }
    }
    
    if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_steel_roach') )
    {
        if ( swordsteel )
        {
            if ( VecDistance( steelcopy.GetWorldPosition(), thePlayer.GetHorseWithInventory().GetWorldPosition() ) > 5.f )
            { 
                if ( steelcopy )
                {
                    steelcopy.Destroy(); 
                }
                if ( steel_dummy )
                {
                    steel_dummy.Destroy(); 
                }
                if ( steelscabcopy )
                {
                    steelscabcopy.Destroy(); 
                }
                //theGame.witcherLog.AddMessage("STEEL COPY DESTROYED, ROACH ELSEWHERE"); 
            }
            
            if ( !thePlayer.GetHorseWithInventory() )
            {
                if ( steelcopy )
                {
                    steelcopy.Destroy(); 
                }
                if ( steel_dummy )
                {
                    steel_dummy.Destroy(); 
                }
                if ( steelscabcopy )
                {
                    steelscabcopy.Destroy(); 
                }
                
                //theGame.witcherLog.AddMessage("STEEL COPY DESTROYED, NO ROACH"); 
            }
            
            if ( !steel_dummy )
            {
                steel_dummy = createsteeldummy_weaponscarrying_roach();
            }
        
            if ( !steelcopy )
            {
                steelcopy = (CEntity)theGame.CreateEntity( (CEntityTemplate)LoadResource(swordsteel.GetReadableName(), true ), Vector( 0, 0, 0 ) );
                steelcopy.AddTag('steel_sword_on_roach_invmod');	
                
                placeweapons_carrying_steel_roach();
            }
            
            if ( !steelcopycomp )
            {
                steelcopycomp = (CMeshComponent)steelcopy.GetComponentByClassName( 'CMeshComponent' );
            }
        }
    }
    else
    if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_steel_body') )
    {
        if ( swordsteel )
        {
            if ( VecDistance( steelcopy.GetWorldPosition(), thePlayer.GetWorldPosition() ) > 5.f )
            { 
                if ( steelcopy )
                {
                    steelcopy.Destroy(); 
                }
                if ( steelcopycopy )
                {
                    steelcopycopy.Destroy(); 
                }
                if ( steel_dummy )
                {
                    steel_dummy.Destroy(); 
                }
                if ( steelscabcopy )
                {
                    steelscabcopy.Destroy(); 
                }
                //theGame.witcherLog.AddMessage("STEEL COPY DESTROYED, PLAYER ELSEWHERE"); 
            }
            
            if ( !steel_dummy )
            {
                steel_dummy = createsteeldummy_weaponscarrying_body();
            }
        
            if ( !steelcopy )
            {
                steelcopy = (CEntity)theGame.CreateEntity( (CEntityTemplate)LoadResource(swordsteel.GetReadableName(), true ), Vector( 0, 0, 0 ) );
                steelcopy.AddTag('steel_sword_on_roach_invmod');	
                
                placeweapons_carrying_steel_body();
            }
            
            if ( !steelcopycomp )
            {
                steelcopycomp = (CMeshComponent)steelcopy.GetComponentByClassName( 'CMeshComponent' );
            }
        }
    }
    else
    {
        if ( steelcopy )
        {
            steelcopy.Destroy(); 
        }
        if ( steelcopycopy )
        {
            steelcopycopy.Destroy(); 
        }
        if ( steel_dummy )
        {
            steel_dummy.Destroy(); 
        }
        if ( steelscabcopy )
        {
            steelscabcopy.Destroy(); 
        }
        if ( steelcopycomp )
        {
            steelcopycomp = NULL; 
        }
    }
        
    // steel scab
    if ( swordsteel )
    {
        if( !thePlayer.GetInventory().IsItemMounted(steelid) && !thePlayer.GetInventory().IsItemHeld(steelid) )  
        {  
            thePlayer.GetInventory().MountItem( steelid, false, false );  
            //theGame.witcherLog.AddMessage("mount back");
        }
    
        if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_steel_scab') || Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_hide_steel_scabbard') )
        {
            thePlayer.GetInventory().GetAllItems(scabbards);	
            for(sw=0; sw<scabbards.Size(); sw+=1)
            {
                if ( thePlayer.GetInventory().GetItemCategory(scabbards[sw]) == 'steel_scabbards' )
                {
                    if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_steel_scab') )
                    {
                        if ( !steelscabcopy && steelcopy )
                        {
                            // mod0_DS_SOH_Patch START
                            if (thePlayer.EnsureDSInitializedAndEnabled() && thePlayer.ds.CheckEquippedArmor(ds_school) && !thePlayer.ds.IsSteelException(steelid))
                            {
                                scab_string = thePlayer.ds.GetSteelScabbardPath(ds_school);
                            }
                            else
                            {
                                scab_string = thePlayer.GetInventory().GetItemEntityUnsafe(scabbards[sw]).GetReadableName();
                            }

                            steelscabcopy = (CEntity)theGame.CreateEntity((CEntityTemplate)LoadResource(scab_string, true), thePlayer.GetWorldPosition());
                            // mod0_DS_SOH_Patch END

                            meshComponent = ( CMeshComponent ) steelscabcopy.GetComponentByClassName( 'CMeshComponent' );
                            meshComponent.SetScale( Vector( 1.03, 1.03, 1 ) );
                            steelscabcopy.AddTag('steel_scab_on_roach_invmod');
                        }
                    }
                    
                    if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_hide_steel_scabbard') )
                    {
                        if ( !scabsteelcomp )
                        {
                            scabsteelcomp = (CDrawableComponent)((thePlayer.GetInventory().GetItemEntityUnsafe(scabbards[sw])).GetMeshComponent());
                        }
                    }
                }
            }
        }
        
        if ( !Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_steel_scab') )
        {
            if ( steelscabcopy )
            {
                steelscabcopy.Destroy(); 
            }
        }
        
    }
    else
    {
        if ( steelscabcopy )
        {
            steelscabcopy.Destroy(); 
        }
        if ( scabsteelcomp )
        {
            scabsteelcomp = NULL; 
        }
    }
}

@replaceMethod(W3InvisibleWeapons)
function Check_Silver_Carrrying()
{
    var swordsilver_temp         : CEntity;

    // mod0_DS_SOH_Patch START
    var scab_string             : string;
    var ds_school               : DSSchoolSet;
    // mod0_DS_SOH_Patch END
    
    if ( thePlayer.GetInventory().GetItemEquippedOnSlot(EES_SilverSword, silverid) )
    {
        swordsilver_temp = thePlayer.GetInventory().GetItemEntityUnsafe(silverid);
        silvercomp = (CDrawableComponent)((thePlayer.GetInventory().GetItemEntityUnsafe(silverid)).GetMeshComponent());
    }
    else 
    { 
        if ( silvercopy )
        {
            silvercopy.Destroy(); 
        }
        if ( silvercopycopy )
        {
            silvercopycopy.Destroy(); 
        }
        if ( silver_dummy )
        {
            silver_dummy.Destroy(); 
        }
        if ( silverscabcopy )
        {
            silverscabcopy.Destroy(); 
        }
        if ( scabsilvercomp )
        {
            scabsilvercomp = NULL; 
        }
        if ( silvercopycomp )
        {
            silvercopycomp = NULL; 
        }
    }
    if ( swordsilver.GetReadableName() != swordsilver_temp.GetReadableName() )
    {
        //theGame.witcherLog.AddMessage("swordsilver.GetReadableName() != swordsilver_temp.GetReadableName()"); 
        swordsilver = swordsilver_temp;
    
        if ( silvercopy )
        {
            silvercopy.Destroy(); 
        }
        if ( silvercopycopy )
        {
            silvercopycopy.Destroy(); 
        }
        if ( silver_dummy )
        {
            silver_dummy.Destroy(); 
        }
        if ( silverscabcopy )
        {
            silverscabcopy.Destroy(); 
        }
        if ( scabsilvercomp )
        {
            scabsilvercomp = NULL; 
        }
        if ( silvercopycomp )
        {
            silvercopycomp = NULL; 
        }
    }
    if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_silver_roach') )
    {
        if ( swordsilver )
        {
            if ( VecDistance( silvercopy.GetWorldPosition(), thePlayer.GetHorseWithInventory().GetWorldPosition() ) > 5.f )
            { 
                if ( silvercopy )
                {
                    silvercopy.Destroy(); 
                }
                if ( silver_dummy )
                {
                    silver_dummy.Destroy(); 
                }
                if ( silverscabcopy )
                {
                    silverscabcopy.Destroy(); 
                }
                //theGame.witcherLog.AddMessage("SILVER COPY DESTROYED, ROACH ELSEWHERE"); 
            }
            
            if ( !thePlayer.GetHorseWithInventory() )
            {
                if ( silvercopy )
                {
                    silvercopy.Destroy(); 
                }
                if ( silver_dummy )
                {
                    silver_dummy.Destroy(); 
                }
                if ( silverscabcopy )
                {
                    silverscabcopy.Destroy(); 
                }
                
                //theGame.witcherLog.AddMessage("SILVER COPY DESTROYED, NO ROACH"); 
            }
            
            if ( !silver_dummy )
            {
                silver_dummy = createsilverdummy_weaponscarrying_roach();
            }
        
            if ( !silvercopy )
            {
                silvercopy = (CEntity)theGame.CreateEntity( (CEntityTemplate)LoadResource(swordsilver.GetReadableName(), true ), Vector( 0, 0, 0 ) );
                silvercopy.AddTag('silver_sword_on_roach_invmod');	
                
                placeweapons_carrying_silver_roach();
            }
            
            if ( !silvercopycomp )
            {
                silvercopycomp = (CMeshComponent)silvercopy.GetComponentByClassName( 'CMeshComponent' );
            }
        }
    }
    else
    if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_silver_body') )
    {
        if ( swordsilver )
        {
            if ( VecDistance( silvercopy.GetWorldPosition(), thePlayer.GetWorldPosition() ) > 5.f )
            { 
                if ( silvercopy )
                {
                    silvercopy.Destroy(); 
                }
                if ( silvercopycopy )
                {
                    silvercopycopy.Destroy(); 
                }
                if ( silver_dummy )
                {
                    silver_dummy.Destroy(); 
                }
                if ( silverscabcopy )
                {
                    silverscabcopy.Destroy(); 
                }
                //theGame.witcherLog.AddMessage("SILVER COPY DESTROYED, PLAYER ELSEWHERE"); 
            }
            
            if ( !silver_dummy )
            {
                silver_dummy = createsilverdummy_weaponscarrying_body();
            }
        
            if ( !silvercopy )
            {
                silvercopy = (CEntity)theGame.CreateEntity( (CEntityTemplate)LoadResource(swordsilver.GetReadableName(), true ), Vector( 0, 0, 0 ) );
                silvercopy.AddTag('silver_sword_on_roach_invmod');	
                
                placeweapons_carrying_silver_body();
            }
            
            if ( !silvercopycomp )
            {
                silvercopycomp = (CMeshComponent)silvercopy.GetComponentByClassName( 'CMeshComponent' );
            }
        }
    }
    else
    {
        if ( silvercopy )
        {
            silvercopy.Destroy(); 
        }
        if ( silvercopycopy )
        {
            silvercopycopy.Destroy(); 
        }
        if ( silver_dummy )
        {
            silver_dummy.Destroy(); 
        }
        if ( silverscabcopy )
        {
            silverscabcopy.Destroy(); 
        }
        if ( silvercopycomp )
        {
            silvercopycomp = NULL; 
        }
    }
    // silver scab
    if ( swordsilver )
    {
        
        if( !thePlayer.GetInventory().IsItemMounted(silverid) && !thePlayer.GetInventory().IsItemHeld(silverid) )  
        {  
            thePlayer.GetInventory().MountItem( silverid, false, false );  
            //theGame.witcherLog.AddMessage("mount back silver");
        }
    
        if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_silver_scab') || Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_hide_silver_scabbard') )
        {
            thePlayer.GetInventory().GetAllItems(scabbards);	
            for(sw=0; sw<scabbards.Size(); sw+=1)
            {
                if ( thePlayer.GetInventory().GetItemCategory(scabbards[sw]) == 'silver_scabbards' )
                {
                    if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_silver_scab') )
                    {
                        if ( !silverscabcopy && silvercopy )
                        {
                            // mod0_DS_SOH_Patch START
                            if (thePlayer.EnsureDSInitializedAndEnabled() && thePlayer.ds.CheckEquippedArmor(ds_school) && !thePlayer.ds.IsSilverException(silverid))
                            {
                                scab_string = thePlayer.ds.GetSilverScabbardPath(ds_school);
                            }
                            else
                            {
                                scab_string = thePlayer.GetInventory().GetItemEntityUnsafe(scabbards[sw]).GetReadableName();
                            }
                            
                            silverscabcopy = (CEntity)theGame.CreateEntity( (CEntityTemplate)LoadResource(scab_string, true), thePlayer.GetWorldPosition());
                            // mod0_DS_SOH_Patch END

                            meshComponent = ( CMeshComponent ) silverscabcopy.GetComponentByClassName( 'CMeshComponent' );
                            meshComponent.SetScale( Vector( 1.03, 1.03, 1 ) );
                            silverscabcopy.AddTag('silver_scab_on_roach_invmod');
                        }
                    }
                    
                    if ( Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_hide_silver_scabbard') )
                    {
                        if ( !scabsilvercomp )
                        {
                            scabsilvercomp = (CDrawableComponent)((thePlayer.GetInventory().GetItemEntityUnsafe(scabbards[sw])).GetMeshComponent());
                        }
                    }
                }
            }
        }
        
        if ( !Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_silver_scab') )
        {
            if ( silverscabcopy )
            {
                silverscabcopy.Destroy(); 
            }
        }
        
    }
    else
    {
        if ( silverscabcopy )
        {
            silverscabcopy.Destroy(); 
        }
        if ( scabsilvercomp )
        {
            scabsilvercomp = NULL; 
        }
    }
}

@addMethod(W3InvisibleWeapons)
public function RefreshSOHScabbards()
{
    if (!wcarrymod())
    {
        return;
    }

    // destroy the scabbards, they will be recomputed on next tick
    if (steelscabcopy)
    {
        steelscabcopy.Destroy();
        steelscabcopy = NULL;
    }
    if (silverscabcopy)
    {
        silverscabcopy.Destroy();
        silverscabcopy = NULL;
    }

    // Nudge WC to place again
    if (!Configsw) 
    {
        Configsw = theGame.GetInGameConfigWrapper(); 
    }

    Configsw.SetVarValue('weapons_carrying_swords_main', 'carrying_enable_changes_swords', "true");
    Configsw.SetVarValue('weapons_carrying_scabbards',   'carrying_enable_changes_scabs',  "true");
}

@addMethod(W3InvisibleWeapons)
public function IsSOHControllingScabbards() : bool
{
    if (Configsw.GetVarValue('weapons_carrying', 'disable_weapcarry_mod'))
    {
        return false;
    }

    // only return true when the preset is not "vanilla"
    return  Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_steel_scab') || Configsw.GetVarValue('weapons_carrying_swords_main', 'carrying_silver_scab');
}

@wrapMethod(CR4IngameMenu)
function OnShowOptionSubmenu(actionType : int, menuTag : int, id : string)
{
    var result: bool;
    var inGameConfig: CInGameConfigWrapper;
    var modEnabled : bool;

    result = wrappedMethod(actionType, menuTag, id);

    if ( id == "weapons_carrying_main"
      || id == "weapons_carrying_swords_main"
      || id == "weapons_carrying_steel_roach"
      || id == "weapons_carrying_steel_body"
      || id == "weapons_carrying_silver_roach"
      || id == "weapons_carrying_silver_body"
      || id == "invisible_weapons_scabbards"
      || id == "weapons_carrying_xbow_main"
      || id == "weapons_carrying_xbow_roach"
      || id == "weapons_carrying_xbow_hip" )
    {
        if (thePlayer.EnsureDSInitializedAndEnabled())
        {
            thePlayer.ds.SetPendingUpdate(true);
        }
    }

    return result;
}

@addMethod(DynamicScabbards)
public function IsCloakInSlot(item : SItemUniqueId, slot: EEquipmentSlots) : bool
{
    var item_name : CName;
    var item_string : string;

    var has_ahw_tag : bool;
    var is_cloak :  bool;
    var is_cape : bool;


    if (slot == EES_Quickslot1 || slot == EES_Quickslot2)
    {
        item_name = thePlayer.inv.GetItemName(item);
        item_string = NameToString(item_name);

        has_ahw_tag = thePlayer.inv.ItemHasTag( item, 'AHW' );
        is_cloak = StrContains( item_string, "Cloak" );
        is_cape = StrContains( item_string, "Cape" );

        if(has_ahw_tag || is_cloak || is_cape || item_name == 'Traveler Kontusz' || item_name == 'NGP Traveler Kontusz')
        {
            return true;
        }
    }

    return false;
}

@wrapMethod(CR4Player)
function HandleScabbardUpdate(item : SItemUniqueId, slot : EEquipmentSlots)
{
    wrappedMethod(item, slot);

    if (ds.IsCloakInSlot(item, slot))
    {
        AddTimer('SetScabbardsDelayed', 0.2, false);
    }
}

@replaceMethod(DynamicScabbards)
function SetScabbards()
{   
    var school : DSSchoolSet;
    var soh : W3InvisibleWeapons;
    var soh_enabled : bool;

    soh = GetInvisibleEnt();
    soh_enabled = soh && soh.IsSOHControllingScabbards();

    if (!enabled)
    {
        ClearScabbards();

        if (soh_enabled)
        {
            soh.RefreshSOHScabbards();
        }

        return;
    }

    if (!CheckEquippedArmor(school))
    {
        ClearScabbards();

        if (soh_enabled)
        {
            soh.RefreshSOHScabbards();
        }

        return;
    }

    if (soh_enabled)
    {
        ClearScabbards();
        soh.RefreshSOHScabbards();
        return;
    }

    UpdateSteelScabbard(school);
    UpdateSilverScabbard(school);
}