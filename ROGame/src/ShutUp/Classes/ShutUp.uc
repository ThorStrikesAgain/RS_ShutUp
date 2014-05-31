class ShutUp extends ROMutator config(ShutUp);

struct VoiceComData
{
    var string Name;
    var int Index;
    var bool Enabled;
};

var config array<VoiceComData> VoiceComConfig;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// This function is called when the map is loading.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function PostBeginPlay()
{
    `Log("ShutUp Started!",, 'ShutUp');
    SetTimer(0.005, true, 'ShutThemUp');

    super.PostBeginPlay();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Periodically removes the delayed battle chatter events.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function ShutThemUp()
{
    local ROGameInfo wROGI;
    local DelayedBattleChatterEvent wEvent;
    local array<DelayedBattleChatterEvent> wEventsToRemove;
    local int wConfigIndex;

    wROGI = ROGameInfo(WorldInfo.Game);
    if(wROGI != none)
    {
        // Find the events to remove.
        foreach wROGI.DelayedBattleChatterEvents(wEvent)
        {
            wConfigIndex = VoiceComConfig.Find('Index',wEvent.VoiceComIndex);
            if(wConfigIndex >= 0 && !VoiceComConfig[wConfigIndex].Enabled)
            {
                wEventsToRemove.AddItem(wEvent);
            }
        }
        
        // Remove the events.
        foreach wEventsToRemove(wEvent)
        {
            wROGI.DelayedBattleChatterEvents.RemoveItem(wEvent);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Initializes a configuration menu for the mutator.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static function InitializeConfigurationMenu(ROUIWidgetSettingsList SettingsList)
{
    local VoiceComData wData;
    local UICheckbox wControl;

    foreach default.VoiceComConfig(wData)
    {
        wControl = SettingsList.AddBooleanSetting(GetFormattedDisplay(wData.Name), "Enable/Disable Chatter", wData.Enabled, OnCheckboxValueChanged);
        wControl.WidgetTag = name("ShutUp_CheckBox_"$wData.Name);

    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Handles the change of a value.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static function OnCheckboxValueChanged(UIObject Sender, int PlayerIndex)
{
    local int wConfigIndex;

    wConfigIndex = default.VoiceComConfig.Find('Name', Mid(Sender.WidgetTag, 16));
    if(wConfigIndex >= 0)
    {
        default.VoiceComConfig[wConfigIndex].Enabled = UICheckBox(Sender).IsChecked();
        StaticSaveConfig();
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Formats a VoiceCom name to a user-friendly string.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static function string GetFormattedDisplay(string iVoiceComName)
{
    local string wName, wDetails;
    local int i;
    
    // Remove the prefix.
    wName = Mid(iVoiceComName, 9);
    
    // Split the name and the details.
    i = InStr(wName, "_");
    if(i >= 0)
    {
        wDetails = Right(wName, Len(wName) - i - 1);
        wName = Left(wName, i);
    }
    
    // Format the variables.
    wName = FormatString(wName);
    if(Len(wDetails) > 0)
    {
        wDetails = " ("$FormatString(wDetails)$")";
    }
    
    return wName$wDetails;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Formats a string to add spaces where it is necessary.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static function string FormatString(string iString)
{
    local string wChar, wPreviousChar, wResult;
    local int i;
    
    wResult = "";
    wPreviousChar = "";
    for(i = 0 ; i < Len(iString) ; i++)
    {
        wChar = Mid(iString, i, 1);
        if(InStr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", wChar) >= 0 &&        // Current character is a capital letter.
           InStr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", wPreviousChar) < 0 && // Previous character was not a capital letter
           wPreviousChar != "_" && wPreviousChar != "")              // Previous character was not _ or empty.
        {
            wResult @= wChar;   // Append a space before the letter.
        }
        else if(wChar == "_" && wPreviousChar != "_" && wPreviousChar != "")    // Previous character was not another underscore or empty.
        {
            wResult $= " ";   // Append a space.
        }
        else
        {
            wResult $= wChar;
        }
        
        wPreviousChar = wChar;
    }
    
    return wResult;
}

defaultproperties
{
}
