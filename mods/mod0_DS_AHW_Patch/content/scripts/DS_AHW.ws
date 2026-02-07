@addMethod(DynamicScabbards)
public function IsAHWActive() : bool
{
    return thePlayer.AHW && FactsDoesExist('AHW') && thePlayer.AHW.Enabled();
}

@wrapMethod(CAHW)
function SetSteelScabbardVisible(visible : bool)
{
    var school : DSSchoolSet;

    wrappedMethod(visible);

    if (!thePlayer.EnsureDSInitializedAndEnabled())
    {
        return;
    }

    if (visible)
    {
        if (thePlayer.ds.CheckEquippedArmor(school))
        {
            thePlayer.ds.UpdateSteelScabbard(school);
        }
    }
    else
    {
        thePlayer.ds.UnloadSteelScabbardAndRestoreVanilla();
    }
}

@wrapMethod(CAHW)
function SetSilverScabbardVisible(visible : bool)
{
    var school : DSSchoolSet;

    wrappedMethod(visible);

    if (!thePlayer.EnsureDSInitializedAndEnabled())
    {
        return;
    }

    if (visible)
    {
        if (thePlayer.ds.CheckEquippedArmor(school))
        {
            thePlayer.ds.UpdateSilverScabbard(school);
        }
    }
    else
    {
        thePlayer.ds.UnloadSilverScabbardAndRestoreVanilla();
    }
}

@wrapMethod(DynamicScabbards)
function SetScabbards()
{
    if (IsAHWActive() && !thePlayer.AHW.globalvis)
    {
        UnloadScabbardsAndRestoreVanilla();
        return;
    }

    wrappedMethod();
}
