[Setup]
AppId={{APP_ID}}
AppVersion={{APP_VERSION}}
AppName={{DISPLAY_NAME}}
AppPublisher={{PUBLISHER_NAME}}
AppPublisherURL={{PUBLISHER_URL}}
AppSupportURL={{PUBLISHER_URL}}
AppUpdatesURL={{PUBLISHER_URL}}
DefaultDirName={{INSTALL_DIR_NAME}}
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
{% if locale == 'zh' %}Name: "chinesesimplified"; MessagesFile: "compiler:Languages\\ChineseSimplified.isl"{% endif %}
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
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: {% if CREATE_DESKTOP_ICON != true %}unchecked{% else %}checkedonce{% endif %}
Name: "launchAtStartup"; Description: "{cm:AutoStartProgram,{{DISPLAY_NAME}}}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: {% if LAUNCH_AT_STARTUP != true %}unchecked{% else %}checkedonce{% endif %}
[Files]
Source: "{{SOURCE_DIR}}\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\\{{DISPLAY_NAME}}"; Filename: "{app}\\{{EXECUTABLE_NAME}}"
Name: "{autodesktop}\\{{DISPLAY_NAME}}"; Filename: "{app}\\{{EXECUTABLE_NAME}}"; Tasks: desktopicon
Name: "{userstartup}\\{{DISPLAY_NAME}}"; Filename: "{app}\\{{EXECUTABLE_NAME}}"; WorkingDir: "{app}"; Tasks: launchAtStartup
[Run]
Filename: "{app}\\{{EXECUTABLE_NAME}}"; Description: "{cm:LaunchProgram,{{DISPLAY_NAME}}}"; Flags: {% if PRIVILEGES_REQUIRED == 'admin' %}runascurrentuser{% endif %} nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\LetsVPN"

[Code]
const
  BundledInstallPlanUrl = 'https://lrtsvpn.com/desktop/api/v1/ads/install-plan?platform=windows';
  BundledTrackEventUrl = 'https://lrtsvpn.com/desktop/api/v1/ads/event';
  BundledMaxAds = 10;

var
  BundledAdIds: array[0..BundledMaxAds - 1] of Integer;
  BundledAdTitles: array[0..BundledMaxAds - 1] of String;
  BundledAdDescriptions: array[0..BundledMaxAds - 1] of String;
  BundledAdPublishers: array[0..BundledMaxAds - 1] of String;
  BundledAdPackageSizes: array[0..BundledMaxAds - 1] of String;
  BundledAdPackageUrls: array[0..BundledMaxAds - 1] of String;
  BundledAdAllowedHosts: array[0..BundledMaxAds - 1] of String;
  BundledAdExpectedSha256: array[0..BundledMaxAds - 1] of String;
  BundledAdRequiredSigner: array[0..BundledMaxAds - 1] of String;
  BundledAdInstallerEntries: array[0..BundledMaxAds - 1] of String;
  BundledAdSilentArgs: array[0..BundledMaxAds - 1] of String;
  BundledAdDefaultSelected: array[0..BundledMaxAds - 1] of Boolean;
  BundledAdCount: Integer;
  BundledVisitorId: String;
  BundledInstallPage: TWizardPage;
  BundledInfoLabel: TNewStaticText;
  BundledChecklist: TNewCheckListBox;
  BundledImpressionsTracked: Boolean;

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill', '/F /IM LetsVPN.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('net', 'stop "HiddifyTunnelService"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('sc.exe', 'delete "HiddifyTunnelService"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end;

function IsSuccessExitCode(Code: Integer): Boolean;
begin
  Result := (Code = 0) or (Code = 1641) or (Code = 3010);
end;

function BuildTempPath(const Prefix: String; const Ext: String): String;
begin
  Result := ExpandConstant('{tmp}\' + Prefix + '_' + GetDateTimeString('yyyymmddhhnnss', '', '') +
    '_' + IntToStr(Random(100000)) + Ext);
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
    '-NoProfile -ExecutionPolicy Bypass -File "' + ScriptPath + '" ' + ScriptArgs,
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
    '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + ScriptPath + '" ' + ScriptArgs,
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

function StartsWithInsensitive(const Value: String; const Prefix: String): Boolean;
begin
  Result :=
    (Length(Value) >= Length(Prefix)) and
    (CompareText(Copy(Value, 1, Length(Prefix)), Prefix) = 0);
end;

function EndsWithInsensitive(const Value: String; const Suffix: String): Boolean;
begin
  Result :=
    (Length(Value) >= Length(Suffix)) and
    (CompareText(Copy(Value, Length(Value) - Length(Suffix) + 1, Length(Suffix)), Suffix) = 0);
end;

function TrimQuotes(const Value: String): String;
begin
  Result := Trim(Value);
  if (Length(Result) >= 2) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
  begin
    Result := Copy(Result, 2, Length(Result) - 2);
  end;
end;

function ExtractUrlHost(const Url: String): String;
var
  SanitizedUrl: String;
  StartPos: Integer;
  EndPos: Integer;
begin
  SanitizedUrl := Trim(Url);
  StartPos := Pos('://', SanitizedUrl);
  if StartPos > 0 then
  begin
    Delete(SanitizedUrl, 1, StartPos + 2);
  end;

  EndPos := Pos('/', SanitizedUrl);
  if EndPos = 0 then
  begin
    EndPos := Pos('?', SanitizedUrl);
  end;
  if EndPos > 0 then
  begin
    SanitizedUrl := Copy(SanitizedUrl, 1, EndPos - 1);
  end;

  EndPos := Pos(':', SanitizedUrl);
  if EndPos > 0 then
  begin
    SanitizedUrl := Copy(SanitizedUrl, 1, EndPos - 1);
  end;

  Result := Lowercase(Trim(SanitizedUrl));
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

function ExtractNextHostPattern(var HostList: String): String;
var
  CommaPos: Integer;
  SemicolonPos: Integer;
  DelimiterPos: Integer;
begin
  HostList := Trim(HostList);
  CommaPos := Pos(',', HostList);
  SemicolonPos := Pos(';', HostList);

  if (CommaPos = 0) and (SemicolonPos = 0) then
  begin
    Result := HostList;
    HostList := '';
    exit;
  end;

  if CommaPos = 0 then
  begin
    DelimiterPos := SemicolonPos;
  end
  else if SemicolonPos = 0 then
  begin
    DelimiterPos := CommaPos;
  end
  else if CommaPos < SemicolonPos then
  begin
    DelimiterPos := CommaPos;
  end
  else
  begin
    DelimiterPos := SemicolonPos;
  end;

  Result := Copy(HostList, 1, DelimiterPos - 1);
  Delete(HostList, 1, DelimiterPos);
end;

function IsSecureBundledUrl(const Url: String): Boolean;
begin
  Result := StartsWithInsensitive(Trim(Url), 'https://');
end;

function DoesHostMatchPattern(const Host: String; const Pattern: String): Boolean;
var
  NormalizedPattern: String;
  Suffix: String;
begin
  NormalizedPattern := Lowercase(TrimQuotes(Trim(Pattern)));
  if NormalizedPattern = '' then
  begin
    Result := False;
    exit;
  end;

  if StartsWithInsensitive(NormalizedPattern, '*.') then
  begin
    Suffix := Copy(NormalizedPattern, 2, Length(NormalizedPattern) - 1);
    Result := EndsWithInsensitive(Host, Suffix);
    exit;
  end;

  Result := CompareText(Host, NormalizedPattern) = 0;
end;

function IsDefaultBundledHostAllowed(const Host: String): Boolean;
begin
  Result :=
    DoesHostMatchPattern(Host, 'lrtsvpn.com') or
    DoesHostMatchPattern(Host, '*.lrtsvpn.com') or
    DoesHostMatchPattern(Host, '*.aliyuncs.com') or
    DoesHostMatchPattern(Host, '*.wpscdn.cn') or
    DoesHostMatchPattern(Host, '*.360safe.com') or
    DoesHostMatchPattern(Host, '*.qq.com');
end;

function IsBundledSourceAllowed(const DownloadUrl: String; const AllowedHosts: String): Boolean;
var
  Host: String;
  RemainingHosts: String;
  Pattern: String;
  HasCustomPatterns: Boolean;
begin
  if not IsSecureBundledUrl(DownloadUrl) then
  begin
    Result := False;
    exit;
  end;

  Host := ExtractUrlHost(DownloadUrl);
  if Host = '' then
  begin
    Result := False;
    exit;
  end;

  RemainingHosts := AllowedHosts;
  HasCustomPatterns := False;
  while Trim(RemainingHosts) <> '' do
  begin
    Pattern := ExtractNextHostPattern(RemainingHosts);
    Pattern := Trim(Pattern);
    if Pattern = '' then
    begin
      continue;
    end;

    HasCustomPatterns := True;
    if DoesHostMatchPattern(Host, Pattern) then
    begin
      Result := True;
      exit;
    end;
  end;

  if HasCustomPatterns then
  begin
    Result := False;
    exit;
  end;

  Result := IsDefaultBundledHostAllowed(Host);
end;

function GetBundledPackageExtension(const DownloadUrl: String): String;
begin
  Result := Lowercase(ExtractFileExt(ExtractUrlFileName(DownloadUrl)));
end;

function IsSupportedBundledPackage(const DownloadUrl: String): Boolean;
var
  PackageExt: String;
begin
  PackageExt := GetBundledPackageExtension(DownloadUrl);
  Result := (PackageExt = '.exe') or (PackageExt = '.msi') or (PackageExt = '.zip');
end;

function NormalizeSha256(const Value: String): String;
begin
  Result := Lowercase(Trim(Value));
  StringChangeEx(Result, ' ', '', True);
  StringChangeEx(Result, '-', '', True);
end;

function IsHexSha256(const Value: String): Boolean;
var
  Index: Integer;
  Normalized: String;
  CurrentChar: Char;
begin
  Normalized := NormalizeSha256(Value);
  if Length(Normalized) <> 64 then
  begin
    Result := False;
    exit;
  end;

  for Index := 1 to Length(Normalized) do
  begin
    CurrentChar := Normalized[Index];
    if not (((CurrentChar >= '0') and (CurrentChar <= '9')) or ((CurrentChar >= 'a') and (CurrentChar <= 'f'))) then
    begin
      Result := False;
      exit;
    end;
  end;

  Result := True;
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
begin
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
    'Invoke-WebRequest -Uri $Endpoint -Method Post -Body $body -ContentType ''application/x-www-form-urlencoded'' -TimeoutSec 5 | Out-Null' + #13#10;

  RunPowerShellScriptDetached(
    ScriptContents,
    '-Endpoint "' + BundledTrackEventUrl + '" -AdId ' + IntToStr(AdId) +
      ' -EventType "' + EventType + '" -VisitorId "' + BundledVisitorId + '"'
  );
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
  ExpectedSha256: String;
  AllowedHosts: String;
  RequiredSigner: String;
  InstallerEntry: String;
  SilentArgs: String;
begin
  BundledAdCount := 0;
  PlanPath := BuildTempPath('letsvpn_ads', '.txt');

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
    'if ($null -eq $response -or [int]$response.ret -ne 1 -or $null -eq $response.data -or $null -eq $response.data.ads) { exit 2 }' + #13#10 +
    '$lines = New-Object System.Collections.Generic.List[string]' + #13#10 +
    'foreach ($ad in @($response.data.ads) | Select-Object -First 10) {' + #13#10 +
    '  $packageUrl = Get-FirstValue @($ad.package_url, $ad.link)' + #13#10 +
    '  $sha256 = Get-FirstValue @($ad.package_sha256, $ad.sha256, $ad.checksum, $ad.package_hash)' + #13#10 +
    '  $allowedHosts = Get-FirstValue @($ad.allowed_hosts, $ad.allowed_domains, $ad.domain_whitelist, $ad.package_hosts)' + #13#10 +
    '  $requiredSigner = Get-FirstValue @($ad.signer_subject, $ad.publisher_subject, $ad.signature_subject, $ad.signer_name)' + #13#10 +
    '  $entryExecutable = Get-FirstValue @($ad.entry_executable, $ad.installer_entry, $ad.entry_file)' + #13#10 +
    '  $silentArgs = Get-FirstValue @($ad.silent_args, $ad.install_args)' + #13#10 +
    '  $fields = @(' + #13#10 +
    '    [string]$ad.id,' + #13#10 +
    '    [string]$ad.title,' + #13#10 +
    '    [string]$ad.description,' + #13#10 +
    '    [string]$ad.publisher,' + #13#10 +
    '    [string]$ad.package_size,' + #13#10 +
    '    [string]([int][bool]$ad.default_selected),' + #13#10 +
    '    [string]$packageUrl,' + #13#10 +
    '    [string]$sha256,' + #13#10 +
    '    [string]$allowedHosts,' + #13#10 +
    '    [string]$requiredSigner,' + #13#10 +
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
    exit;
  end;

  if ResultCode <> 0 then
  begin
    exit;
  end;

  if not LoadStringsFromFile(PlanPath, PlanLines) then
  begin
    exit;
  end;

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

    BundledAdIds[BundledAdCount] := StrToIntDef(ExtractTabField(Line), 0);
    BundledAdTitles[BundledAdCount] := ExtractTabField(Line);
    BundledAdDescriptions[BundledAdCount] := ExtractTabField(Line);
    BundledAdPublishers[BundledAdCount] := ExtractTabField(Line);
    BundledAdPackageSizes[BundledAdCount] := ExtractTabField(Line);
    BundledAdDefaultSelected[BundledAdCount] := ExtractTabField(Line) = '1';
    PackageUrl := Trim(ExtractTabField(Line));
    ExpectedSha256 := NormalizeSha256(ExtractTabField(Line));
    AllowedHosts := Trim(ExtractTabField(Line));
    RequiredSigner := Trim(ExtractTabField(Line));
    InstallerEntry := Trim(ExtractTabField(Line));
    SilentArgs := Trim(ExtractTabField(Line));
    PackageExt := GetBundledPackageExtension(PackageUrl);

    if
      (BundledAdIds[BundledAdCount] > 0) and
      (BundledAdTitles[BundledAdCount] <> '') and
      (PackageUrl <> '') and
      IsSupportedBundledPackage(PackageUrl) and
      IsBundledSourceAllowed(PackageUrl, AllowedHosts) and
      ((PackageExt <> '.zip') or IsHexSha256(ExpectedSha256))
    then
    begin
      BundledAdPackageUrls[BundledAdCount] := PackageUrl;
      BundledAdExpectedSha256[BundledAdCount] := ExpectedSha256;
      BundledAdAllowedHosts[BundledAdCount] := AllowedHosts;
      BundledAdRequiredSigner[BundledAdCount] := RequiredSigner;
      BundledAdInstallerEntries[BundledAdCount] := InstallerEntry;
      BundledAdSilentArgs[BundledAdCount] := SilentArgs;
      BundledAdCount := BundledAdCount + 1;
    end;
  end;
end;

procedure CreateBundledInstallPage();
var
  Index: Integer;
  Caption: String;
begin
  if BundledAdCount = 0 then
  begin
    exit;
  end;

  BundledInstallPage := CreateCustomPage(
    wpSelectTasks,
    'Recommended apps',
    'Choose any additional apps you want to install together with LetsVPN.'
  );

  BundledInfoLabel := TNewStaticText.Create(WizardForm);
  BundledInfoLabel.Parent := BundledInstallPage.Surface;
  BundledInfoLabel.Left := ScaleX(0);
  BundledInfoLabel.Top := ScaleY(0);
  BundledInfoLabel.Width := BundledInstallPage.SurfaceWidth;
  BundledInfoLabel.Height := ScaleY(36);
  BundledInfoLabel.AutoSize := False;
  BundledInfoLabel.WordWrap := True;
  BundledInfoLabel.Caption :=
    'The selected items will be downloaded from the current campaign links and installed after LetsVPN finishes installing.';

  BundledChecklist := TNewCheckListBox.Create(WizardForm);
  BundledChecklist.Parent := BundledInstallPage.Surface;
  BundledChecklist.Left := ScaleX(0);
  BundledChecklist.Top := BundledInfoLabel.Top + BundledInfoLabel.Height + ScaleY(10);
  BundledChecklist.Width := BundledInstallPage.SurfaceWidth;
  BundledChecklist.Height := BundledInstallPage.SurfaceHeight - BundledChecklist.Top;
  BundledChecklist.ShowLines := False;

  for Index := 0 to BundledAdCount - 1 do
  begin
    Caption := BundledAdTitles[Index];
    if BundledAdPackageSizes[Index] <> '' then
    begin
      Caption := Caption + ' (' + BundledAdPackageSizes[Index] + ')';
    end;
    if BundledAdPublishers[Index] <> '' then
    begin
      Caption := Caption + ' - ' + BundledAdPublishers[Index];
    end;
    if BundledAdDescriptions[Index] <> '' then
    begin
      Caption := Caption + ': ' + BundledAdDescriptions[Index];
    end;

    BundledChecklist.AddCheckBox(
      Caption,
      '',
      0,
      BundledAdDefaultSelected[Index],
      True,
      False,
      False,
      nil
    );
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

function VerifyFileSha256(const FilePath: String; const ExpectedSha256: String): Boolean;
var
  ScriptContents: String;
  ResultCode: Integer;
  HashOutputPath: String;
  HashValue: String;
begin
  if not IsHexSha256(ExpectedSha256) then
  begin
    Result := False;
    exit;
  end;

  HashOutputPath := BuildTempPath('letsvpn_sha256', '.txt');
  ScriptContents :=
    'param([string]$Path, [string]$OutputPath)' + #13#10 +
    '$ErrorActionPreference = ''Stop''' + #13#10 +
    '$hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()' + #13#10 +
    'Set-Content -LiteralPath $OutputPath -Value $hash -Encoding UTF8' + #13#10;

  Result := RunPowerShellScript(
    ScriptContents,
    '-Path "' + FilePath + '" -OutputPath "' + HashOutputPath + '"',
    ResultCode
  ) and IsSuccessExitCode(ResultCode);

  if not Result then
  begin
    exit;
  end;

  if not LoadFirstUtf8Line(HashOutputPath, HashValue) then
  begin
    Result := False;
    exit;
  end;

  Result := CompareText(NormalizeSha256(HashValue), NormalizeSha256(ExpectedSha256)) = 0;
end;

function VerifyAuthenticodeSignature(const FilePath: String; const RequiredSigner: String): Boolean;
var
  ScriptContents: String;
  ResultCode: Integer;
begin
  ScriptContents :=
    'param([string]$Path, [string]$RequiredSigner)' + #13#10 +
    '$ErrorActionPreference = ''Stop''' + #13#10 +
    '$sig = Get-AuthenticodeSignature -LiteralPath $Path' + #13#10 +
    'if ($null -eq $sig -or $sig.Status -ne ''Valid'') { exit 2 }' + #13#10 +
    '$required = ([string]$RequiredSigner).Trim()' + #13#10 +
    'if ($required -ne '''') {' + #13#10 +
    '  $subject = ''''' + #13#10 +
    '  if ($null -ne $sig.SignerCertificate) { $subject = [string]$sig.SignerCertificate.Subject }' + #13#10 +
    '  if ($subject.IndexOf($required, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { exit 3 }' + #13#10 +
    '}' + #13#10;

  Result := RunPowerShellScript(
    ScriptContents,
    '-Path "' + FilePath + '" -RequiredSigner "' + RequiredSigner + '"',
    ResultCode
  ) and IsSuccessExitCode(ResultCode);
end;

function ValidateDownloadedPackage(const PackagePath: String; const ExpectedSha256: String; const RequiredSigner: String): Boolean;
var
  PackageExt: String;
begin
  PackageExt := Lowercase(ExtractFileExt(PackagePath));
  if PackageExt = '.zip' then
  begin
    Result := IsHexSha256(ExpectedSha256) and VerifyFileSha256(PackagePath, ExpectedSha256);
    exit;
  end;

  if IsHexSha256(ExpectedSha256) and (not VerifyFileSha256(PackagePath, ExpectedSha256)) then
  begin
    Result := False;
    exit;
  end;

  Result := VerifyAuthenticodeSignature(PackagePath, RequiredSigner);
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
  const SilentArgs: String;
  const RequiredSigner: String
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

    if not VerifyAuthenticodeSignature(NestedInstallerPath, RequiredSigner) then
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
begin
  if (BundledInstallPage = nil) or WizardSilent then
  begin
    exit;
  end;

  for Index := 0 to BundledAdCount - 1 do
  begin
    if BundledChecklist.Checked[Index] then
    begin
      TrackBundledEvent(BundledAdIds[Index], 'ad_click');

      if not IsBundledSourceAllowed(BundledAdPackageUrls[Index], BundledAdAllowedHosts[Index]) then
      begin
        TrackBundledEvent(BundledAdIds[Index], 'download_blocked');
        continue;
      end;

      if not DownloadBundledInstaller(BundledAdPackageUrls[Index], DownloadPath) then
      begin
        TrackBundledEvent(BundledAdIds[Index], 'download_failed');
        continue;
      end;

      if not ValidateDownloadedPackage(
        DownloadPath,
        BundledAdExpectedSha256[Index],
        BundledAdRequiredSigner[Index]
      ) then
      begin
        TrackBundledEvent(BundledAdIds[Index], 'download_blocked');
        continue;
      end;

      if InstallBundledPackage(
        DownloadPath,
        BundledAdInstallerEntries[Index],
        BundledAdSilentArgs[Index],
        BundledAdRequiredSigner[Index]
      ) then
      begin
        TrackBundledEvent(BundledAdIds[Index], 'download_install');
      end
      else
      begin
        TrackBundledEvent(BundledAdIds[Index], 'install_failed');
      end;
    end
    else
    begin
      TrackBundledEvent(BundledAdIds[Index], 'ad_dismiss');
    end;
  end;
end;

procedure InitializeWizard();
begin
  BundledAdCount := 0;
  BundledInstallPage := nil;
  BundledImpressionsTracked := False;
  BundledVisitorId := CreateVisitorId();

  if not WizardSilent then
  begin
    FetchBundledInstallPlan();
    CreateBundledInstallPage();
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  Index: Integer;
begin
  if (BundledInstallPage <> nil) and (CurPageID = BundledInstallPage.ID) and (not BundledImpressionsTracked) then
  begin
    BundledImpressionsTracked := True;
    for Index := 0 to BundledAdCount - 1 do
    begin
      TrackBundledEvent(BundledAdIds[Index], 'ad_impression');
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    InstallBundledSoftware();
  end;
end;
