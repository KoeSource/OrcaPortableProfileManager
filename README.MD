# Orca Portable Profile Manager

![Example Image](https://github.com/KoeSource/OrcaPortableProfileManager/blob/master/ppm.jpg)

### Preamble

Orca Slicer Portable saves all configuration data,<br>
as well as printer and filament profiles, in %appdata%.<br>
This defeats the purpose of a portable version.<br>
That's why I wrote this little script.

### Features

- Create and delete profiles<br>
- Launch OrcaSlicer using the selected profile<br>
- Launch OrcaSlicer directly using a specific profile without displaying OrcaPPM.<br>
- Saves the last profile used.<br>
- INI-File for manual configuration.<br>

### Instructions

- Place OrcaPPM.exe in the OrcaPortal folder. <br>
  (OrcaPPM.exe must be in the same location as orca-slicer.exe.)<br>
- Run OrcaPPM.exe<br>
- The OrcaPPM.ini file is created the first time the program is launched.<br>
- A new profile is created with the prefix `_OrcaPPM_`. <br><br>
If you want to start a profile directly without displaying the GUI,<br>
use the `DirectLaunchParam=` option in the inifile.<br>
for example:<br>
`DirectLaunchParam=-datadir MyProfile` <br>
(DirectLaunchParam passes all parameters directly to orca-slicer.exe)

### Compile it yourself

- Install AutoHotkey v2
- Right-click on “OrcaPPM.ahk” and select “Compile Script (GUI)...”
- Click “Convert”