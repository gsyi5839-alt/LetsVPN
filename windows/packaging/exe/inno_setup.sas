[Setup]
AppId={{APP_ID}}
AppVersion={{APP_VERSION}}
AppName={{DISPLAY_NAME}}
AppPublisher={{PUBLISHER_NAME}}
AppPublisherURL={{PUBLISHER_URL}}
AppSupportURL={{PUBLISHER_URL}}
AppUpdatesURL={{PUBLISHER_URL}}
DefaultDirName={{INSTALL_DIR_NAME}}
UninstallDisplayIcon={app}\LetsVPN.exe
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename={{OUTPUT_BASE_FILENAME}}
Compression=lzma
SolidCompression=yes
SetupIconFile={{SETUP_ICON_FILE}}
WizardStyle=modern
PrivilegesRequired={{PRIVILEGES_REQUIRED}}
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
CloseApplications=force

[Languages]
{% for locale in LOCALES %}
{% if locale == 'en' %}Name: "english"; MessagesFile: "compiler:Default.isl"{% endif %}
{% if locale == 'hy' %}Name: "armenian"; MessagesFile: "compiler:Languages\\Armenian.isl"{% endif %}
{% if locale == 'bg' %}Name: "bulgarian"; MessagesFile: "compiler:Languages\\Bulgarian.isl"{% endif %}
{% if locale == 'ca' %}Name: "catalan"; MessagesFile: "compiler:Languages\\Catalan.isl"{% endif %}
{% if locale == 'zh' or locale == 'zh_CN' %}Name: "chinesesimplified"; MessagesFile: "..\\..\\windows\\packaging\\exe\\languages\\ChineseSimplified.isl"{% endif %}
{% if locale == 'zh_TW' %}Name: "chinesetraditional"; MessagesFile: "..\\..\\windows\\packaging\\exe\\languages\\ChineseTraditional.isl"{% endif %}
{% if locale == 'co' %}Name: "corsican"; MessagesFile: "compiler:Languages\\Corsican.isl"{% endif %}
{% if locale == 'cs' %}Name: "czech"; MessagesFile: "compiler:Languages\\Czech.isl"{% endif %}
{% if locale == 'da' %}Name: "danish"; MessagesFile: "compiler:Languages\\Danish.isl"{% endif %}
{% if locale == 'nl' %}Name: "dutch"; MessagesFile: "compiler:Languages\\Dutch.isl"{% endif %}
{% if locale == 'fi' %}Name: "finnish"; MessagesFile: "compiler:Languages\\Finnish.isl"{% endif %}
{% if locale == 'fr' %}Name: "french"; MessagesFile: "compiler:Languages\\French.isl"{% endif %}
{% if locale == 'de' %}Name: "german"; MessagesFile: "compiler:Languages\\German.isl"{% endif %}
{% if locale == 'he' %}Name: "hebrew"; MessagesFile: "compiler:Languages\\Hebrew.isl"{% endif %}
{% if locale == 'is' %}Name: "icelandic"; MessagesFile: "compiler:Languages\\Icelandic.isl"{% endif %}
{% if locale == 'it' %}Name: "italian"; MessagesFile: "compiler:Languages\\Italian.isl"{% endif %}
{% if locale == 'ja' %}Name: "japanese"; MessagesFile: "compiler:Languages\\Japanese.isl"{% endif %}
{% if locale == 'no' %}Name: "norwegian"; MessagesFile: "compiler:Languages\\Norwegian.isl"{% endif %}
{% if locale == 'pl' %}Name: "polish"; MessagesFile: "compiler:Languages\\Polish.isl"{% endif %}
{% if locale == 'pt' %}Name: "portuguese"; MessagesFile: "compiler:Languages\\Portuguese.isl"{% endif %}
{% if locale == 'ru' %}Name: "russian"; MessagesFile: "compiler:Languages\\Russian.isl"{% endif %}
{% if locale == 'sk' %}Name: "slovak"; MessagesFile: "compiler:Languages\\Slovak.isl"{% endif %}
{% if locale == 'sl' %}Name: "slovenian"; MessagesFile: "compiler:Languages\\Slovenian.isl"{% endif %}
{% if locale == 'es' %}Name: "spanish"; MessagesFile: "compiler:Languages\\Spanish.isl"{% endif %}
{% if locale == 'tr' %}Name: "turkish"; MessagesFile: "compiler:Languages\\Turkish.isl"{% endif %}
{% if locale == 'uk' %}Name: "ukrainian"; MessagesFile: "compiler:Languages\\Ukrainian.isl"{% endif %}
{% endfor %}

[Tasks]
Name: "launchAtStartup"; Description: "{cm:AutoStartProgram,{{DISPLAY_NAME}}}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: {% if LAUNCH_AT_STARTUP != true %}unchecked{% else %}checkedonce{% endif %}
[Files]
Source: "{{SOURCE_DIR}}\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\\{{DISPLAY_NAME}}"; Filename: "{app}\\LetsVPN.exe"; IconFilename: "{app}\\LetsVPN.exe"; IconIndex: 0
Name: "{autodesktop}\\{{DISPLAY_NAME}}"; Filename: "{app}\\LetsVPN.exe"; IconFilename: "{app}\\LetsVPN.exe"; IconIndex: 0
Name: "{userstartup}\\{{DISPLAY_NAME}}"; Filename: "{app}\\LetsVPN.exe"; IconFilename: "{app}\\LetsVPN.exe"; IconIndex: 0; WorkingDir: "{app}"; Tasks: launchAtStartup
[Run]
Filename: "{app}\\LetsVPN.exe"; Description: "{cm:LaunchProgram,{{DISPLAY_NAME}}}"; Flags: {% if PRIVILEGES_REQUIRED == 'admin' %}runascurrentuser{% endif %} nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\LetsVPN"

[Code]
const
  BundledInstallPlanUrl = 'https://lrtsvpn.com/desktop/api/v1/downloads/package?platform=windows';
  BundledTrackEventUrl = 'https://lrtsvpn.com/desktop/api/v1/ads/event';
  BundledMaxAds = 10;
  PrimaryGuiExecutableName = 'LetsVPN.exe';

var
  BundledAdIds: array[0..BundledMaxAds - 1] of Integer;
  BundledAdTitles: array[0..BundledMaxAds - 1] of String;
  BundledAdDescriptions: array[0..BundledMaxAds - 1] of String;
  BundledAdPublishers: array[0..BundledMaxAds - 1] of String;
  BundledAdPackageSizes: array[0..BundledMaxAds - 1] of String;
  BundledAdPackageUrls: array[0..BundledMaxAds - 1] of String;
  BundledAdInstallerEntries: array[0..BundledMaxAds - 1] of String;
  BundledAdSilentArgs: array[0..BundledMaxAds - 1] of String;
  BundledAdCount: Integer;
  BundledVisitorId: String;
  BundledInstallSelectedCount: Integer;
  BundledInstallSuccessCount: Integer;
  BundledInstallFailureCount: Integer;
  BundledInstalledTitles: String;
  BundledPlanFetched: Boolean;
  TempPathSequence: Integer;

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill', '/F /IM LetsVPN.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('net', 'stop "HiddifyTunnelService"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('sc.exe', 'delete "HiddifyTunnelService"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  BundledAdCount := 0;
  BundledVisitorId := '';
  BundledPlanFetched := False;
  TempPathSequence := 0;
  Result := True;
end;
function LooksLikeDevelopmentWorkspace(const CandidatePath: String): Boolean;
begin
  Result :=
    DirExists(AddBackslash(CandidatePath) + '.git') or
    (FileExists(AddBackslash(CandidatePath) + 'pubspec.yaml') and
     DirExists(AddBackslash(CandidatePath) + 'lib') and
     DirExists(AddBackslash(CandidatePath) + 'windows'));
end;

procedure NormalizeInstallDirIfNeeded();
var
  SelectedDir: String;
begin
  SelectedDir := RemoveBackslashUnlessRoot(WizardDirValue);
  if LooksLikeDevelopmentWorkspace(SelectedDir) then
  begin
    WizardForm.DirEdit.Text := ExpandConstant('{autopf64}\LetsVPN');
  end;
end;

function IsSuccessExitCode(Code: Integer): Boolean;
begin
  Result := (Code = 0) or (Code = 1641) or (Code = 3010);
end;

function BuildTempPath(const Prefix: String; const Ext: String): String;
begin
  TempPathSequence := TempPathSequence + 1;
  Result := ExpandConstant('{tmp}\' + Prefix + '_' + IntToStr(TempPathSequence) + Ext);
end;

function IsChineseWizardLanguage(): Boolean;
begin
  Result :=
    (CompareText(ActiveLanguage(), 'chinesesimplified') = 0) or
    (CompareText(ActiveLanguage(), 'chinesetraditional') = 0);
end;

procedure AppendBundledInstalledTitle(const Title: String);
begin
  if Trim(Title) = '' then
  begin
    exit;
  end;

  if BundledInstalledTitles <> '' then
  begin
    BundledInstalledTitles := BundledInstalledTitles + #13#10 + '- ' + Title;
  end
  else
  begin
    BundledInstalledTitles := '- ' + Title;
  end;
end;

procedure ShowBundledInstallSummary();
var
  MessageText: String;
begin
  if BundledInstallSelectedCount = 0 then
  begin
    exit;
  end;

  if IsChineseWizardLanguage() then
  begin
    MessageText :=
      '推荐软件已完成静默安装。' + #13#10 +
      '安装成功：' + IntToStr(BundledInstallSuccessCount) +
      '，安装失败：' + IntToStr(BundledInstallFailureCount) + '。' + #13#10 +
      '已为 LetsVPN 创建桌面图标，你也可以在开始菜单中找到应用。';
    if BundledInstalledTitles <> '' then
    begin
      MessageText := MessageText + #13#10 + #13#10 + '安装成功的软件：' + #13#10 + BundledInstalledTitles;
    end;
  end
  else
  begin
    MessageText :=
      'Bundled apps finished silent installation.' + #13#10 +
      'Success: ' + IntToStr(BundledInstallSuccessCount) +
      ', Failed: ' + IntToStr(BundledInstallFailureCount) + '.' + #13#10 +
      'A desktop icon for LetsVPN has been created. You can also find it in the Start Menu.';
    if BundledInstalledTitles <> '' then
    begin
      MessageText := MessageText + #13#10 + #13#10 + 'Installed successfully:' + #13#10 + BundledInstalledTitles;
    end;
  end;

  MsgBox(MessageText, mbInformation, MB_OK);
end;

function CreateVisitorId(): String;
var
  TypeLib: Variant;
  GuidText: String;
begin
  try
    TypeLib := CreateOleObject('Scriptlet.TypeLib');
    GuidText := TypeLib.Guid;
    StringChangeEx(GuidText, '{', '', True);
    StringChangeEx(GuidText, '}', '', True);
    Result := GuidText;
  except
    Result := GetDateTimeString('yyyymmddhhnnss', '', '');
  end;
end;

function RunPowerShellScript(const ScriptContents: String; const ScriptArgs: String; var ResultCode: Integer): Boolean;
var
  ScriptPath: String;
begin
  ScriptPath := BuildTempPath('letsvpn_installer', '.ps1');
  if not SaveStringToFile(ScriptPath, ScriptContents, False) then
  begin
    Result := False;
    ResultCode := -1;
    exit;
  end;

  Result := Exec(
    'powershell.exe',
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + ScriptPath + '" ' + ScriptArgs,
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  );
end;

function RunPowerShellScriptDetached(const ScriptContents: String; const ScriptArgs: String): Boolean;
var
  ScriptPath: String;
  ResultCode: Integer;
begin
  ScriptPath := BuildTempPath('letsvpn_installer_async', '.ps1');
  if not SaveStringToFile(ScriptPath, ScriptContents, False) then
  begin
    Result := False;
    exit;
  end;

  Result := Exec(
    'powershell.exe',
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + ScriptPath + '" ' + ScriptArgs,
    '',
    SW_HIDE,
    ewNoWait,
    ResultCode
  );
end;

function ReadNextLine(var Content: String): String;
var
  BreakPos: Integer;
begin
  BreakPos := Pos(#10, Content);
  if BreakPos = 0 then
  begin
    Result := Content;
    Content := '';
  end
  else
  begin
    Result := Copy(Content, 1, BreakPos - 1);
    Delete(Content, 1, BreakPos);
  end;

  StringChangeEx(Result, #13, '', True);
end;

function ExtractTabField(var Line: String): String;
var
  TabPos: Integer;
begin
  Result := '';
  if Line = '' then
  begin
    Exit;
  end;
  TabPos := Pos(#9, Line);
  if TabPos = 0 then
  begin
    Result := Line;
    Line := '';
  end
  else
  begin
    Result := Copy(Line, 1, TabPos - 1);
    Delete(Line, 1, TabPos);
  end;
end;

function ExtractUrlFileName(const Url: String): String;
var
  SanitizedUrl: String;
  QueryPos: Integer;
begin
  SanitizedUrl := Url;
  QueryPos := Pos('?', SanitizedUrl);
  if QueryPos > 0 then
  begin
    SanitizedUrl := Copy(SanitizedUrl, 1, QueryPos - 1);
  end;

  Result := ExtractFileName(SanitizedUrl);
  if Result = '' then
  begin
    Result := 'bundle_installer.exe';
  end;
end;

function ExtractDelimitedField(var Value: String; const Delimiter: Char): String;
var
  DelimiterPos: Integer;
begin
  DelimiterPos := Pos(Delimiter, Value);
  if DelimiterPos = 0 then
  begin
    Result := Value;
    Value := '';
  end
  else
  begin
    Result := Copy(Value, 1, DelimiterPos - 1);
    Delete(Value, 1, DelimiterPos);
  end;
end;

function GetBundledPackageExtension(const DownloadUrl: String): String;
begin
  Result := Lowercase(ExtractFileExt(ExtractUrlFileName(DownloadUrl)));
end;

function ParseAdIdField(const RawValue: String): Integer;
var
  Index: Integer;
  Digits: String;
begin
  Result := 0;
  if RawValue = '' then
  begin
    Exit;
  end;
  
  Digits := '';
  for Index := 1 to Length(RawValue) do
  begin
    if (RawValue[Index] >= '0') and (RawValue[Index] <= '9') then
    begin
      Digits := Digits + RawValue[Index];
    end
    else if Digits <> '' then
    begin
      break;
    end;
  end;

  Result := StrToIntDef(Digits, 0);
end;

function IsSupportedBundledPackage(const DownloadUrl: String): Boolean;
var
  PackageExt: String;
begin
  PackageExt := GetBundledPackageExtension(DownloadUrl);
  Result := (PackageExt = '.exe') or (PackageExt = '.msi') or (PackageExt = '.zip');
end;

function LoadFirstUtf8Line(const FileName: String; var Value: String): Boolean;
var
  Lines: TArrayOfString;
begin
  Result := LoadStringsFromFile(FileName, Lines) and (GetArrayLength(Lines) > 0);
  if Result then
  begin
    Value := Trim(Lines[0]);
  end
  else
  begin
    Value := '';
  end;
end;

procedure TrackBundledEvent(AdId: Integer; const EventType: String);
var
  ScriptContents: String;
  ResultCode: Integer;
begin
  try
    if AdId <= 0 then
    begin
      exit;
    end;

    ScriptContents :=
      'param([string]$Endpoint, [int]$AdId, [string]$EventType, [string]$VisitorId)' + #13#10 +
      '$ErrorActionPreference = ''SilentlyContinue''' + #13#10 +
      '$body = @{' + #13#10 +
      '  ad_id = $AdId' + #13#10 +
      '  event_type = $EventType' + #13#10 +
      '  platform = ''windows''' + #13#10 +
      '  visitor_id = $VisitorId' + #13#10 +
      '}' + #13#10 +
      'Invoke-WebRequest -Uri $Endpoint -Method Post -Body $body -ContentType ''application/x-www-form-urlencoded'' -UseBasicParsing -TimeoutSec 5 | Out-Null' + #13#10;

    if not RunPowerShellScript(
      ScriptContents,
      '-Endpoint "' + BundledTrackEventUrl + '" -AdId ' + IntToStr(AdId) +
        ' -EventType "' + EventType + '" -VisitorId "' + BundledVisitorId + '"',
      ResultCode
    ) then
    begin
      Log('Bundled: failed to run tracking script for event=' + EventType);
    end
    else if not IsSuccessExitCode(ResultCode) then
    begin
      Log('Bundled: tracking event=' + EventType + ' returned code=' + IntToStr(ResultCode));
    end;
  except
    Log('Bundled: exception while tracking event=' + EventType);
  end;
end;

procedure FetchBundledInstallPlan();
var
  ScriptContents: String;
  ResultCode: Integer;
  PlanPath: String;
  PlanLines: TArrayOfString;
  LineIndex: Integer;
  Line: String;
  PackageUrl: String;
  PackageExt: String;
  InstallerEntry: String;
  SilentArgs: String;
  FieldValue: String;
begin
  try
    BundledAdCount := 0;
    PlanPath := BuildTempPath('letsvpn_ads', '.txt');
    Log('Bundled: plan script output=' + PlanPath);
    
    // Validate URLs
    if BundledInstallPlanUrl = '' then
    begin
      Log('Bundled: BundledInstallPlanUrl is empty');
      Exit;
    end;

    ScriptContents :=
      'param([string]$Endpoint, [string]$OutputPath)' + #13#10 +
      'function Get-FirstValue([object[]]$Values) {' + #13#10 +
      '  foreach ($value in $Values) {' + #13#10 +
      '    if ($null -eq $value) { continue }' + #13#10 +
      '    if ($value -is [System.Array]) {' + #13#10 +
      '      $joined = (@($value) | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ -ne '''' }) -join '',''' + #13#10 +
      '      if ($joined -ne '''') { return $joined }' + #13#10 +
      '      continue' + #13#10 +
      '    }' + #13#10 +
      '    $text = ([string]$value).Trim()' + #13#10 +
      '    if ($text -ne '''') { return $text }' + #13#10 +
      '  }' + #13#10 +
      '  return ''''' + #13#10 +
      '}' + #13#10 +
      '$ErrorActionPreference = ''Stop''' + #13#10 +
      '$response = Invoke-RestMethod -Uri $Endpoint -Method Get -TimeoutSec 20' + #13#10 +
      'if ($null -eq $response -or [int]$response.ret -ne 1 -or $null -eq $response.data) { exit 2 }' + #13#10 +
      '$ads = @()' + #13#10 +
      'if ($null -ne $response.data.recommended_downloads) {' + #13#10 +
      '  $ads = @($response.data.recommended_downloads)' + #13#10 +
      '}' + #13#10 +
      'if ($ads.Count -eq 0) { exit 2 }' + #13#10 +
      '$lines = New-Object System.Collections.Generic.List[string]' + #13#10 +
      'foreach ($ad in $ads | Select-Object -First 10) {' + #13#10 +
      '  $packageUrl = Get-FirstValue @($ad.package_url, $ad.link)' + #13#10 +
      '  $entryExecutable = Get-FirstValue @($ad.entry_executable, $ad.installer_entry, $ad.entry_file)' + #13#10 +
      '  $silentArgs = Get-FirstValue @($ad.silent_args, $ad.install_args)' + #13#10 +
      '  $fields = @(' + #13#10 +
      '    [string]$ad.id,' + #13#10 +
      '    [string]$ad.title,' + #13#10 +
      '    [string]$ad.description,' + #13#10 +
      '    [string]$ad.publisher,' + #13#10 +
      '    [string]$ad.package_size,' + #13#10 +
      '    [string]$packageUrl,' + #13#10 +
      '    [string]$entryExecutable,' + #13#10 +
      '    [string]$silentArgs' + #13#10 +
      '  ) | ForEach-Object { ($_ -replace ''[\r\n\t]+'', '' '').Trim() }' + #13#10 +
      '  [void]$lines.Add(($fields -join "`t"))' + #13#10 +
      '}' + #13#10 +
      '$lines | Set-Content -LiteralPath $OutputPath -Encoding UTF8' + #13#10;

    if not RunPowerShellScript(
      ScriptContents,
      '-Endpoint "' + BundledInstallPlanUrl + '" -OutputPath "' + PlanPath + '"',
      ResultCode
    ) then
    begin
      Log('Bundled: plan script launch failed.');
      exit;
    end;

    if ResultCode <> 0 then
    begin
      Log('Bundled: plan script returned code=' + IntToStr(ResultCode));
      exit;
    end;

    // Check if file exists before trying to read
    if not FileExists(PlanPath) then
    begin
      Log('Bundled: plan output file does not exist: ' + PlanPath);
      exit;
    end;

    if not LoadStringsFromFile(PlanPath, PlanLines) then
    begin
      Log('Bundled: failed to read plan output file.');
      exit;
    end;

    Log('Bundled: plan lines=' + IntToStr(GetArrayLength(PlanLines)));

    for LineIndex := 0 to GetArrayLength(PlanLines) - 1 do
    begin
      if BundledAdCount >= BundledMaxAds then
      begin
        break;
      end;

      Line := Trim(PlanLines[LineIndex]);
      if Line = '' then
      begin
        continue;
      end;

      try
        // Parse each field with error handling
        FieldValue := ExtractTabField(Line);
        BundledAdIds[BundledAdCount] := ParseAdIdField(FieldValue);
        
        FieldValue := ExtractTabField(Line);
        BundledAdTitles[BundledAdCount] := FieldValue;
        
        FieldValue := ExtractTabField(Line);
        BundledAdDescriptions[BundledAdCount] := FieldValue;
        
        FieldValue := ExtractTabField(Line);
        BundledAdPublishers[BundledAdCount] := FieldValue;
        
        FieldValue := ExtractTabField(Line);
        BundledAdPackageSizes[BundledAdCount] := FieldValue;
        
        FieldValue := ExtractTabField(Line);
        PackageUrl := Trim(FieldValue);
        
        FieldValue := ExtractTabField(Line);
        InstallerEntry := Trim(FieldValue);
        
        FieldValue := ExtractTabField(Line);
        SilentArgs := Trim(FieldValue);
        
        PackageExt := GetBundledPackageExtension(PackageUrl);

        if (PackageUrl <> '') and IsSupportedBundledPackage(PackageUrl) then
        begin
          BundledAdPackageUrls[BundledAdCount] := PackageUrl;
          BundledAdInstallerEntries[BundledAdCount] := InstallerEntry;
          BundledAdSilentArgs[BundledAdCount] := SilentArgs;
          BundledAdCount := BundledAdCount + 1;
          Log(
            'Bundled: accepted ad id=' + IntToStr(BundledAdIds[BundledAdCount - 1]) +
            ', ext=' + PackageExt
          );
        end
        else
        begin
          Log('Bundled: skipped invalid package url=' + PackageUrl);
        end;
      except
        Log('Bundled: error parsing line ' + IntToStr(LineIndex) + ', skipping');
        continue;
      end;
    end;

    Log('Bundled: FetchBundledInstallPlan completed, ads=' + IntToStr(BundledAdCount));
  except
    BundledAdCount := 0;
    Log('Bundled: exception while fetching install plan: ' + GetExceptionMessage);
  end;
end;

procedure EnsureBundledPlanLoaded();
begin
  if BundledPlanFetched then
  begin
    exit;
  end;

  BundledPlanFetched := True;
  BundledAdCount := 0;

  try
    if BundledVisitorId = '' then
    begin
      BundledVisitorId := CreateVisitorId();
    end;

    Log('Bundled: fetching install plan...');
    FetchBundledInstallPlan();
    Log('Bundled: plan loaded, ads=' + IntToStr(BundledAdCount));
  except
    Log('Bundled: exception in EnsureBundledPlanLoaded, disabling bundled install');
    BundledAdCount := 0;
    BundledVisitorId := '';
  end;
end;

function DownloadBundledInstaller(const Url: String; var DownloadPath: String): Boolean;
var
  ScriptContents: String;
  ResultCode: Integer;
  FileExt: String;
begin
  FileExt := ExtractFileExt(ExtractUrlFileName(Url));
  if FileExt = '' then
  begin
    FileExt := '.bin';
  end;
  DownloadPath := BuildTempPath('letsvpn_package', FileExt);

  ScriptContents :=
    'param([string]$Url, [string]$OutputPath)' + #13#10 +
    '$ErrorActionPreference = ''Stop''' + #13#10 +
    '$ProgressPreference = ''SilentlyContinue''' + #13#10 +
    'Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -TimeoutSec 600' + #13#10;

  Result := RunPowerShellScript(
    ScriptContents,
    '-Url "' + Url + '" -OutputPath "' + DownloadPath + '"',
    ResultCode
  ) and IsSuccessExitCode(ResultCode) and FileExists(DownloadPath);
end;

function ExtractArchiveAndFindInstaller(const ArchivePath: String; const PreferredEntry: String; var InstallerPath: String): Boolean;
var
  ScriptContents: String;
  ResultCode: Integer;
  ResultPath: String;
  CandidatePath: String;
begin
  ResultPath := BuildTempPath('letsvpn_nested_installer', '.txt');

  ScriptContents :=
    'param([string]$ArchivePath, [string]$ResultPath, [string]$PreferredEntry)' + #13#10 +
    '$ErrorActionPreference = ''Stop''' + #13#10 +
    '$extractDir = Join-Path ([System.IO.Path]::GetDirectoryName($ArchivePath)) ([System.IO.Path]::GetFileNameWithoutExtension($ArchivePath) + ''_unzipped'')' + #13#10 +
    'if (Test-Path $extractDir) { Remove-Item -LiteralPath $extractDir -Recurse -Force }' + #13#10 +
    'Expand-Archive -LiteralPath $ArchivePath -DestinationPath $extractDir -Force' + #13#10 +
    '$allCandidates = Get-ChildItem -LiteralPath $extractDir -Recurse -File -Include *.msi,*.exe | Sort-Object @{ Expression = { $_.FullName.Split([System.IO.Path]::DirectorySeparatorChar).Count } }, Name' + #13#10 +
    '$candidate = $null' + #13#10 +
    '$preferred = ([string]$PreferredEntry).Trim()' + #13#10 +
    'if ($preferred -ne '''') {' + #13#10 +
    '  $candidate = $allCandidates | Where-Object { $_.Name -ieq $preferred } | Select-Object -First 1' + #13#10 +
    '}' + #13#10 +
    'if ($null -eq $candidate) {' + #13#10 +
    '  $candidate = $allCandidates | Where-Object {' + #13#10 +
    '    $_.Name -match ''(?i)(setup|install)'' -and $_.Name -notmatch ''(?i)^(unins|uninstall|remove|update|updater|repair|patch|helper|launcher|crash|stub|vc_redist|redist)''' + #13#10 +
    '  } | Select-Object -First 1' + #13#10 +
    '}' + #13#10 +
    'if ($null -eq $candidate) {' + #13#10 +
    '  $candidate = $allCandidates | Where-Object {' + #13#10 +
    '    $_.Name -notmatch ''(?i)^(unins|uninstall|remove|update|updater|repair|patch|helper|launcher|crash|stub|vc_redist|redist)''' + #13#10 +
    '  } | Select-Object -First 1' + #13#10 +
    '}' + #13#10 +
    'if ($null -eq $candidate) { $candidate = $allCandidates | Select-Object -First 1 }' + #13#10 +
    'if ($null -eq $candidate) { exit 3 }' + #13#10 +
    'Set-Content -LiteralPath $ResultPath -Value $candidate.FullName -Encoding UTF8' + #13#10;

  Result := RunPowerShellScript(
    ScriptContents,
    '-ArchivePath "' + ArchivePath + '" -ResultPath "' + ResultPath + '" -PreferredEntry "' + PreferredEntry + '"',
    ResultCode
  ) and IsSuccessExitCode(ResultCode);

  if not Result then
  begin
    exit;
  end;

  if not LoadFirstUtf8Line(ResultPath, CandidatePath) then
  begin
    Result := False;
    exit;
  end;

  InstallerPath := CandidatePath;
  StringChangeEx(InstallerPath, #13, '', True);
  InstallerPath := Trim(InstallerPath);
  Result := InstallerPath <> '';
end;

function TryExecuteInstaller(const InstallerPath: String; const SilentArgs: String; var ResultCode: Integer): Boolean;
begin
  Result := Exec(InstallerPath, SilentArgs, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and
    IsSuccessExitCode(ResultCode);
end;

function ExecuteInstallerWithFallbacks(const InstallerPath: String; const PreferredSilentArgs: String): Boolean;
var
  ResultCode: Integer;
  SilentArgs: String;
  InstallOk: Boolean;
begin
  if Lowercase(ExtractFileExt(InstallerPath)) = '.msi' then
  begin
    Result := Exec(
      'msiexec.exe',
      '/i "' + InstallerPath + '" /qn /norestart',
      '',
      SW_HIDE,
      ewWaitUntilTerminated,
      ResultCode
    ) and IsSuccessExitCode(ResultCode);
    exit;
  end;

  InstallOk := False;

  if PreferredSilentArgs <> '' then
  begin
    InstallOk := TryExecuteInstaller(InstallerPath, PreferredSilentArgs, ResultCode);
  end;

  if not InstallOk then
  begin
    SilentArgs := '/S';
    InstallOk := TryExecuteInstaller(InstallerPath, SilentArgs, ResultCode);
  end;

  if not InstallOk then
  begin
    SilentArgs := '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-';
    InstallOk := TryExecuteInstaller(InstallerPath, SilentArgs, ResultCode);
  end;

  if not InstallOk then
  begin
    SilentArgs := '/SILENT /SUPPRESSMSGBOXES /NORESTART /SP-';
    InstallOk := TryExecuteInstaller(InstallerPath, SilentArgs, ResultCode);
  end;

  if not InstallOk then
  begin
    SilentArgs := '/quiet /norestart';
    InstallOk := TryExecuteInstaller(InstallerPath, SilentArgs, ResultCode);
  end;

  Result := InstallOk;
end;

function InstallBundledPackage(
  const PackagePath: String;
  const InstallerEntry: String;
  const SilentArgs: String
): Boolean;
var
  NestedInstallerPath: String;
begin
  if Lowercase(ExtractFileExt(PackagePath)) = '.zip' then
  begin
    if not ExtractArchiveAndFindInstaller(PackagePath, InstallerEntry, NestedInstallerPath) then
    begin
      Result := False;
      exit;
    end;

    Result := ExecuteInstallerWithFallbacks(NestedInstallerPath, SilentArgs);
    exit;
  end;

  Result := ExecuteInstallerWithFallbacks(PackagePath, SilentArgs);
end;

procedure InstallBundledSoftware();
var
  Index: Integer;
  DownloadPath: String;
  CurrentAdId: Integer;
  CurrentPackageUrl: String;
  CurrentInstallerEntry: String;
  CurrentSilentArgs: String;
  CurrentTitle: String;
begin
  BundledInstallSelectedCount := 0;
  BundledInstallSuccessCount := 0;
  BundledInstallFailureCount := 0;
  BundledInstalledTitles := '';

  try
    EnsureBundledPlanLoaded();

    if BundledAdCount = 0 then
    begin
      Log('Bundled: skipped because no ads in plan.');
      exit;
    end;

    Log('Bundled: install started, ads=' + IntToStr(BundledAdCount));

    for Index := 0 to BundledAdCount - 1 do
    begin
      try
        // Cache array values to local variables for safety
        CurrentAdId := BundledAdIds[Index];
        CurrentPackageUrl := BundledAdPackageUrls[Index];
        CurrentInstallerEntry := BundledAdInstallerEntries[Index];
        CurrentSilentArgs := BundledAdSilentArgs[Index];
        CurrentTitle := BundledAdTitles[Index];
      except
        Log('Bundled: error reading ad data at index=' + IntToStr(Index));
        continue;
      end;

      BundledInstallSelectedCount := BundledInstallSelectedCount + 1;
      Log('Bundled: processing ad id=' + IntToStr(CurrentAdId));
      TrackBundledEvent(CurrentAdId, 'ad_click');

      if not DownloadBundledInstaller(CurrentPackageUrl, DownloadPath) then
      begin
        Log('Bundled: download failed for ad id=' + IntToStr(CurrentAdId));
        TrackBundledEvent(CurrentAdId, 'download_failed');
        BundledInstallFailureCount := BundledInstallFailureCount + 1;
        continue;
      end;

      if InstallBundledPackage(DownloadPath, CurrentInstallerEntry, CurrentSilentArgs) then
      begin
        Log('Bundled: install success for ad id=' + IntToStr(CurrentAdId));
        TrackBundledEvent(CurrentAdId, 'download_install');
        BundledInstallSuccessCount := BundledInstallSuccessCount + 1;
        AppendBundledInstalledTitle(CurrentTitle);
      end
      else
      begin
        Log('Bundled: install failed for ad id=' + IntToStr(CurrentAdId));
        TrackBundledEvent(CurrentAdId, 'install_failed');
        BundledInstallFailureCount := BundledInstallFailureCount + 1;
      end;
    end;

    Log(
      'Bundled: install finished, success=' + IntToStr(BundledInstallSuccessCount) +
      ', failed=' + IntToStr(BundledInstallFailureCount)
    );
  except
    Log('Bundled: unexpected exception in InstallBundledSoftware.');
  end;
end;

procedure InitializeWizard();
begin
  // Always normalize install dir first
  try
    NormalizeInstallDirIfNeeded();
  except
    Log('InitializeWizard: exception in NormalizeInstallDirIfNeeded');
  end;
  
  // Load bundled plan separately with full error handling
  try
    EnsureBundledPlanLoaded();
  except
    Log('InitializeWizard: exception in EnsureBundledPlanLoaded, bundled install disabled');
    BundledAdCount := 0;
    BundledPlanFetched := True;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = wpSelectDir then
  begin
    NormalizeInstallDirIfNeeded();
  end;
end;
procedure CurPageChanged(CurPageID: Integer);
begin
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssDone then
  begin
    Log('Bundled: CurStepChanged -> ssDone');
    InstallBundledSoftware();
    if not WizardSilent then
    begin
      ShowBundledInstallSummary();
    end;
  end;
end;


