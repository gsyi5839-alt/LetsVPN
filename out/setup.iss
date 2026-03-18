[Setup]
AppId={{6L903538-42B1-4596-G479-BJ779F21A65D}
AppVersion=4.1.2
AppName=LetsVPN
AppPublisher=Hiddify
AppPublisherURL=https://github.com/hiddify/hiddify-app
AppSupportURL=https://github.com/hiddify/hiddify-app
AppUpdatesURL=https://github.com/hiddify/hiddify-app
DefaultDirName={autopf64}\LetsVPN
DisableProgramGroupPage=yes
OutputDir=C:\LetsVPN\out
OutputBaseFilename=LetsVPN-Windows-Setup-x64
Compression=lzma
SolidCompression=yes
SetupIconFile=C:\LetsVPN\windows\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
CloseApplications=force

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
Name: "launchAtStartup"; Description: "{cm:AutoStartProgram,LetsVPN}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Program Files\hiddify\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\LetsVPN"; Filename: "{app}\LetsVPN.exe"
Name: "{autodesktop}\LetsVPN"; Filename: "{app}\LetsVPN.exe"; Tasks: desktopicon
Name: "{userstartup}\LetsVPN"; Filename: "{app}\LetsVPN.exe"; WorkingDir: "{app}"; Tasks: launchAtStartup

[Run]
Filename: "{app}\LetsVPN.exe"; Description: "{cm:LaunchProgram,LetsVPN}"; Flags: runascurrentuser nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\Hiddify"

[Code]
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill', '/F /IM LetsVPN.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
  Exec('net', 'stop "HiddifyTunnelService"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
  Exec('sc.exe', 'delete "HiddifyTunnelService"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
  Result := True;
end;
