;@Ahk2Exe-SetMainIcon OrcaPPM.ico
;@Ahk2Exe-ExeName OrcaPPM
#Requires AutoHotkey v2.0
SetWorkingDir(A_ScriptDir)

; --- DIESE CODE-WERTE ENTSPRECHEN EXAKT DEN INI-SCHLÜSSELN ---
global Prefix            := "_OrcaPPM_"
global Parameter         := "-datadir"
global DirectLaunchParam := ""

global ConfigFile := "OrcaPPM.ini"
global ProfileList := []     ; Speichert die reinen Anzeigenamen (Suffixe)
global FullFolderList := []  ; Speichert die echten Ordnernamen (mit Präfix)
global MyGui := ""
global ChoiceDDL := ""
global NewProfileInput := ""

; INI prüfen, Werte abgleichen und Ordner scannen
LastSelectedFull := LoadConfigAndScanFolders()

; AUTOMATION BYPASS: Wenn DirectLaunchParam gesetzt ist, sofort ausführen und beenden
if (DirectLaunchParam != "") {
    try {
        Run('orca-slicer.exe ' DirectLaunchParam)
    } catch {
        MsgBox("orca-slicer.exe could not be found in this folder. (Triggered via DirectLaunchParam)", "Error", 16 + 262144)
    }
    ExitApp()
}

; GUI erstellen (wird nur geladen, wenn DirectLaunchParam leer ist)
MyGui := Gui("+AlwaysOnTop -MinimizeBox", "Orca Portable Profile Manager")
MyGui.SetFont("s10", "Segoe UI")

; Reihe 1: Label ganz oben
MyGui.Add("Text", "x10 y10 w250", "Add new profile:")

; Reihe 2: Eingabefeld und Plus-Button nebeneinander
NewProfileInput := MyGui.Add("Edit", "x10 y35 w210 h25 -WantReturn")
NewProfileInput.Hint := "Name new profile..."
AddBtn := MyGui.Add("Button", "x225 y34 w35 h27", "+")
AddBtn.OnEvent("Click", AddProfileFolder)

; Reihe 3: Zweites Label
MyGui.Add("Text", "x10 y75 w250", "Select an OrcaSlicer profile to load:")

; Reihe 4: Dropdown-Liste (zeigt nur Suffixe) und Minus-Button nebeneinander
ChoiceDDL := MyGui.Add("DropDownList", "vSelectedProfile x10 y100 w210", ProfileList)
DeleteBtn := MyGui.Add("Button", "x225 y99 w35 h27", "-")
DeleteBtn.OnEvent("Click", RemoveProfileFolder)

; Automatisch das zuletzt genutzte Profil wählen (Anzeigenamen herleiten)
if (LastSelectedFull != "" && HasValue(FullFolderList, LastSelectedFull)) {
    LastSuffix := SubStr(LastSelectedFull, StrLen(Prefix) + 1)
    ChoiceDDL.Text := LastSuffix
} else if (ProfileList.Length > 0) {
    ChoiceDDL.Choose(1)
}

; Reihe 5: Start-Button
LaunchBtn := MyGui.Add("Button", "x10 y140 w250 h35 Default", "Launch OrcaSlicer")
LaunchBtn.OnEvent("Click", LaunchOrca)
MyGui.OnEvent("Close", (*) => ExitApp())

; --- ENTER-TASTE INTELLIGENT ABFANGEN ---
#HotIf WinActive("Orca Portable Profile Manager") && MyGui.FocusedCtrl == NewProfileInput
Enter::
NumpadEnter::
{
    ; Prüfen, ob das Textfeld leer ist
    if (Trim(NewProfileInput.Value) == "") {
        LaunchOrca(LaunchBtn) ; Wenn leer: Orca direkt starten
    } else {
        AddProfileFolder(AddBtn) ; Wenn Text drin: Profil erstellen
    }
}
#HotIf

MyGui.Show("w270 h190")

; --- FUNCTIONS ---

LoadConfigAndScanFolders() {
    global ConfigFile, ProfileList, FullFolderList, Prefix, Parameter, DirectLaunchParam
    ProfileList := []
    FullFolderList := []
    
    if !FileExist(ConfigFile) {
        IniWrite(Prefix, ConfigFile, "Settings", "Prefix")
        IniWrite(Parameter, ConfigFile, "Settings", "Parameter")
        IniWrite(DirectLaunchParam, ConfigFile, "Settings", "DirectLaunchParam")
        IniWrite("", ConfigFile, "Settings", "LastUsed")
    }

    ; 1. PRÄFIX-SYNCHRONISATION
    IniPrefix := IniRead(ConfigFile, "Settings", "Prefix", "")
    if (IniPrefix != Prefix && IniPrefix != "") {
        Prefix := IniPrefix
    } else {
        IniWrite(Prefix, ConfigFile, "Settings", "Prefix")
    }

    ; 2. PARAMETER-SYNCHRONISATION
    IniParam := IniRead(ConfigFile, "Settings", "Parameter", "")
    if (IniParam != Parameter && IniParam != "") {
        Parameter := IniParam
    } else {
        IniWrite(Parameter, ConfigFile, "Settings", "Parameter")
    }

    ; 3. DIRECT LAUNCH PARAMETER-SYNCHRONISATION
    IniDirect := IniRead(ConfigFile, "Settings", "DirectLaunchParam", "")
    if (IniDirect != DirectLaunchParam && IniDirect != "") {
        DirectLaunchParam := IniDirect
    } else {
        IniWrite(DirectLaunchParam, ConfigFile, "Settings", "DirectLaunchParam")
    }

    PrefixLen := StrLen(Prefix)

    Loop Files, Prefix "*", "D" {
        FullFolderList.Push(A_LoopFileName)
        Suffix := SubStr(A_LoopFileName, PrefixLen + 1)
        ProfileList.Push(Suffix)
    }
    
    Last := IniRead(ConfigFile, "Settings", "LastUsed", "")
    return Last
}

AddProfileFolder(*) {
    global Prefix, ProfileList, ChoiceDDL, NewProfileInput
    
    CleanInput := Trim(NewProfileInput.Value)
    if (CleanInput == "")
        return
        
    FullFolderName := Prefix . CleanInput
    
    if !DirExist(FullFolderName) {
        DirCreate(FullFolderName)
    }
    
    NewProfileInput.Value := ""
    
    LoadConfigAndScanFolders()
    ChoiceDDL.Delete()
    ChoiceDDL.Add(ProfileList)
    ChoiceDDL.Text := CleanInput
}

RemoveProfileFolder(*) {
    global ConfigFile, ProfileList, FullFolderList, ChoiceDDL, Prefix
    
    SelectedSuffix := ChoiceDDL.Text
    if (SelectedSuffix == "") {
        MsgBox("No profile selected to remove.", "Warning", 48 + 262144)
        return
    }
    
    FullFolderName := Prefix . SelectedSuffix
    
    Result := MsgBox("Are you sure you want to permanently delete the profile '" SelectedSuffix "' and all its contents?", "Confirm Delete", 4 + 262144)
    if (Result == "No")
        return

    if DirExist(FullFolderName) {
        try {
            DirDelete(FullFolderName, 1)
        } catch {
            MsgBox("Could not delete folder. It might be open in another program.", "Error", 16 + 262144)
            return
        }
    }
    
    Last := IniRead(ConfigFile, "Settings", "LastUsed", "")
    if (Last == FullFolderName) {
        IniWrite("", ConfigFile, "Settings", "LastUsed")
    }

    LoadConfigAndScanFolders()
    ChoiceDDL.Delete()
    ChoiceDDL.Add(ProfileList)
    if (ProfileList.Length > 0) {
        ChoiceDDL.Choose(1)
    }
}

LaunchOrca(*) {
    global MyGui, ConfigFile, Prefix, Parameter
    Saved := MyGui.Submit()
    SelectedSuffix := Saved.SelectedProfile
    
    if (SelectedSuffix == "") {
        MsgBox("Please select or add a profile to launch OrcaSlicer.", "Error", 16 + 262144)
        MyGui.Show()
        return
    }
    
    FullFolderName := Prefix . SelectedSuffix
    
    IniWrite(FullFolderName, ConfigFile, "Settings", "LastUsed")
    
    try {
        Run('orca-slicer.exe ' Parameter ' "' FullFolderName '"')
    } catch {
        MsgBox("orca-slicer.exe could not be found in this folder.", "Error", 16 + 262144)
    }
    ExitApp()
}

; --- UTILITY HELPERS ---

HasValue(Haystack, Needle) {
    for Value in Haystack {
        if (Value = Needle)
            return true
    }
    return false
}
