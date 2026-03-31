; Inno Setup Script for LetsVPN
[Setup]
AppId={{LetsVPN-4.1.2}
AppVersion=4.1.2+40102
AppName=LetsVPN
AppPublisher=LetsVPN Team
AppPublisherURL=https://lrtsvpn.com
AppSupportURL=https://lrtsvpn.com
AppUpdatesURL=https://lrtsvpn.com
DefaultDirName={autopf}\LetsVPN
UninstallDisplayIcon={app}\LetsVPN.exe
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=LetsVPN-windows-x64
Compression=lzma
SolidCompression=yes
SetupIconFile=..\..\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
CloseApplications=force

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "languages\ChineseSimplified.isl"
Name: "chinesetraditional"; MessagesFile: "languages\ChineseTraditional.isl"

[Files]
Source: "..\..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{autoprograms}\LetsVPN"; Filename: "{app}\LetsVPN.exe"
Name: "{autodesktop}\LetsVPN"; Filename: "{app}\LetsVPN.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Run]
Filename: "{app}\LetsVPN.exe"; Description: "{cm:LaunchProgram,LetsVPN}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\*"
