; *** Inno Setup version 6.5.0+ English messages ***
;
; To download user-contributed translations of this file, go to:
;   https://jrsoftware.org/files/istrans/
;
; Note: When translating this text, do not add periods (.) to the end of
; messages that didn't have them already, because on those messages Inno
; Setup adds the periods automatically (appending a period would result in
; two periods being displayed).

[LangOptions]
; The following three entries are very important. Be sure to read and
; understand the '[LangOptions] section' topic in the help file.
LanguageName=繁體中文
LanguageID=$0404
; LanguageCodePage should always be set if possible, even if this file is Unicode
; For English it's set to zero anyway because English only uses ASCII characters
LanguageCodePage=950
; If the language you are translating to requires special font faces or
; sizes, uncomment any of the following entries and change them accordingly.
;DialogFontName=
;DialogFontSize=9
;DialogFontBaseScaleWidth=7
;DialogFontBaseScaleHeight=15
;WelcomeFontName=Segoe UI
;WelcomeFontSize=14

[Messages]

; *** Application titles
SetupAppTitle=安裝
SetupWindowTitle=安裝 - %1
UninstallAppTitle=解除安裝
UninstallAppFullTitle=%1 解除安裝

; *** Misc. common
InformationTitle=資訊
ConfirmTitle=確認
ErrorTitle=錯誤

; *** SetupLdr messages
SetupLdrStartupMessage=這將安裝 %1。是否繼續？
LdrCannotCreateTemp=無法建立暫存檔，安裝已中止
LdrCannotExecTemp=無法在暫存目錄中執行檔案，安裝已中止
HelpTextNote=

; *** Startup error messages
LastErrorMessage=%1。%n%n錯誤 %2：%3
SetupFileMissing=安裝目錄中缺少檔案 %1。請修正此問題，或重新取得一份新的程式副本。
SetupFileCorrupt=安裝檔案已損毀。請重新取得一份新的程式副本。
SetupFileCorruptOrWrongVer=安裝檔案已損毀，或與目前安裝程式版本不相容。請修正此問題，或重新取得一份新的程式副本。
InvalidParameter=命令列傳入了無效參數：%n%n%1
SetupAlreadyRunning=安裝程式已在執行中。
WindowsVersionNotSupported=此程式不支援您目前執行的 Windows 版本。
WindowsServicePackRequired=此程式需要 %1 Service Pack %2 或更新版本。
NotOnThisPlatform=此程式無法在 %1 上執行。
OnlyOnThisPlatform=此程式必須在 %1 上執行。
OnlyOnTheseArchitectures=此程式只能安裝在採用下列處理器架構的 Windows 版本上：%n%n%1
WinVersionTooLowError=此程式需要 %1 %2 或更新版本。
WinVersionTooHighError=此程式不能安裝在 %1 %2 或更新版本上。
AdminPrivilegesRequired=安裝此程式時，您必須以系統管理員身分登入。
PowerUserPrivilegesRequired=安裝此程式時，您必須以系統管理員身分登入，或屬於 Power Users 群組。
SetupAppRunningError=安裝程式偵測到 %1 目前正在執行。%n%n請先關閉它的所有執行個體，然後按一下「確定」繼續，或按一下「取消」退出。
UninstallAppRunningError=解除安裝程式偵測到 %1 目前正在執行。%n%n請先關閉它的所有執行個體，然後按一下「確定」繼續，或按一下「取消」退出。

; *** Startup questions
PrivilegesRequiredOverrideTitle=選擇安裝模式
PrivilegesRequiredOverrideInstruction=請選擇安裝模式
PrivilegesRequiredOverrideText1=%1 可以為所有使用者安裝（需要系統管理員權限），也可以僅為您自己安裝。
PrivilegesRequiredOverrideText2=%1 可以僅為您自己安裝，也可以為所有使用者安裝（需要系統管理員權限）。
PrivilegesRequiredOverrideAllUsers=為所有使用者安裝(&A)
PrivilegesRequiredOverrideAllUsersRecommended=為所有使用者安裝（建議）(&A)
PrivilegesRequiredOverrideCurrentUser=僅為我安裝(&M)
PrivilegesRequiredOverrideCurrentUserRecommended=僅為我安裝（建議）(&M)

; *** Misc. errors
ErrorCreatingDir=安裝程式無法建立目錄「%1」
ErrorTooManyFilesInDir=無法在目錄「%1」中建立檔案，因為其中包含的檔案過多

; *** Setup common messages
ExitSetupTitle=退出安裝
ExitSetupMessage=安裝尚未完成。如果現在退出，程式將不會被安裝。%n%n您可以稍後再次執行安裝程式以完成安裝。%n%n是否退出安裝？
AboutSetupMenuItem=關於安裝程式(&A)...
AboutSetupTitle=關於安裝程式
AboutSetupMessage=%1 版本 %2%n%3%n%n%1 首頁：%n%4
AboutSetupNote=
TranslatorNote=

; *** Buttons
ButtonBack=< 上一步(&B)
ButtonNext=下一步(&N) >
ButtonInstall=安裝(&I)
ButtonOK=確定
ButtonCancel=取消
ButtonYes=是(&Y)
ButtonYesToAll=全部是(&A)
ButtonNo=否(&N)
ButtonNoToAll=全部否(&O)
ButtonFinish=完成(&F)
ButtonBrowse=瀏覽(&B)...
ButtonWizardBrowse=瀏覽(&R)...
ButtonNewFolder=新增資料夾(&M)

; *** "Select Language" dialog messages
SelectLanguageTitle=選擇安裝語言
SelectLanguageLabel=請選擇安裝過程中使用的語言。

; *** Common wizard text
ClickNext=按一下「下一步」繼續，或按一下「取消」退出安裝。
BeveledLabel=
BrowseDialogTitle=瀏覽資料夾
BrowseDialogLabel=從下列清單中選擇資料夾，然後按一下「確定」。
NewFolderName=新增資料夾

; *** "Welcome" wizard page
WelcomeLabel1=歡迎使用 [name] 安裝精靈
WelcomeLabel2=這將在您的電腦上安裝 [name/ver]。%n%n建議您在繼續之前先關閉所有其他應用程式。

; *** "Password" wizard page
WizardPassword=密碼
PasswordLabel1=此安裝受密碼保護。
PasswordLabel3=請輸入密碼，然後按一下「下一步」繼續。密碼區分大小寫。
PasswordEditLabel=密碼(&P)：
IncorrectPassword=您輸入的密碼不正確，請再試一次。

; *** "License Agreement" wizard page
WizardLicense=授權協議
LicenseLabel=繼續之前，請先閱讀以下重要資訊。
LicenseLabel3=請閱讀以下授權協議。您必須接受本協議條款後才能繼續安裝。
LicenseAccepted=我接受協議(&A)
LicenseNotAccepted=我不接受協議(&D)

; *** "Information" wizard pages
WizardInfoBefore=資訊
InfoBeforeLabel=繼續之前，請先閱讀以下重要資訊。
InfoBeforeClickLabel=準備繼續時，請按一下「下一步」。
WizardInfoAfter=資訊
InfoAfterLabel=繼續之前，請先閱讀以下重要資訊。
InfoAfterClickLabel=準備繼續時，請按一下「下一步」。

; *** "User Information" wizard page
WizardUserInfo=使用者資訊
UserInfoDesc=請輸入您的資訊。
UserInfoName=使用者名稱(&U)：
UserInfoOrg=組織(&O)：
UserInfoSerial=序號(&S)：
UserInfoNameRequired=您必須輸入名稱。

; *** "Select Destination Location" wizard page
WizardSelectDir=選擇目標位置
SelectDirDesc=[name] 應安裝到哪裡？
SelectDirLabel3=安裝程式將把 [name] 安裝到以下資料夾中。
SelectDirBrowseLabel=按一下「下一步」繼續。如果您想選擇其他資料夾，請按一下「瀏覽」。
DiskSpaceGBLabel=至少需要 [gb] GB 的可用磁碟空間。
DiskSpaceMBLabel=至少需要 [mb] MB 的可用磁碟空間。
CannotInstallToNetworkDrive=安裝程式無法安裝到網路磁碟機。
CannotInstallToUNCPath=安裝程式無法安裝到 UNC 路徑。
InvalidPath=您必須輸入帶有磁碟機代號的完整路徑，例如：%n%nC:\APP%n%n或採用下列形式的 UNC 路徑：%n%n\\server\share
InvalidDrive=您選擇的磁碟機或 UNC 共用不存在或無法存取。請選擇其他位置。
DiskSpaceWarningTitle=磁碟空間不足
DiskSpaceWarning=安裝至少需要 %1 KB 可用空間，但所選磁碟機只有 %2 KB 可用。%n%n仍要繼續嗎？
DirNameTooLong=資料夾名稱或路徑過長。
InvalidDirName=資料夾名稱無效。
BadDirName32=資料夾名稱不能包含下列任一字元：%n%n%1
DirExistsTitle=資料夾已存在
DirExists=資料夾：%n%n%1%n%n已存在。仍要安裝到該資料夾嗎？
DirDoesntExistTitle=資料夾不存在
DirDoesntExist=資料夾：%n%n%1%n%n不存在。要建立該資料夾嗎？

; *** "Select Components" wizard page
WizardSelectComponents=選擇元件
SelectComponentsDesc=要安裝哪些元件？
SelectComponentsLabel2=請選擇您要安裝的元件；清除您不想安裝的元件。準備繼續時，請按一下「下一步」。
FullInstallation=完整安裝
; if possible don't translate 'Compact' as 'Minimal' (I mean 'Minimal' in your language)
CompactInstallation=精簡安裝
CustomInstallation=自訂安裝
NoUninstallWarningTitle=元件已存在
NoUninstallWarning=安裝程式偵測到下列元件已安裝在您的電腦上：%n%n%1%n%n取消勾選這些元件不會將其解除安裝。%n%n仍要繼續嗎？
ComponentSize1=%1 KB
ComponentSize2=%1 MB
ComponentsDiskSpaceGBLabel=目前選擇至少需要 [gb] GB 的磁碟空間。
ComponentsDiskSpaceMBLabel=目前選擇至少需要 [mb] MB 的磁碟空間。

; *** "Select Additional Tasks" wizard page
WizardSelectTasks=選擇附加工作
SelectTasksDesc=要執行哪些附加工作？
SelectTasksLabel2=請選擇安裝 [name] 時需要由安裝程式執行的附加工作，然後按一下「下一步」。

; *** "Select Start Menu Folder" wizard page
WizardSelectProgramGroup=選擇開始功能表資料夾
SelectStartMenuFolderDesc=安裝程式應將程式捷徑放在哪裡？
SelectStartMenuFolderLabel3=安裝程式會在下列開始功能表資料夾中建立程式捷徑。
SelectStartMenuFolderBrowseLabel=按一下「下一步」繼續。如果您想選擇其他資料夾，請按一下「瀏覽」。
MustEnterGroupName=您必須輸入資料夾名稱。
GroupNameTooLong=資料夾名稱或路徑過長。
InvalidGroupName=資料夾名稱無效。
BadGroupName=資料夾名稱不能包含下列任一字元：%n%n%1
NoProgramGroupCheck2=不要建立開始功能表資料夾(&D)

; *** "Ready to Install" wizard page
WizardReady=準備安裝
ReadyLabel1=安裝程式已準備好開始在您的電腦上安裝 [name]。
ReadyLabel2a=按一下「安裝」繼續安裝；如果您想檢視或變更任何設定，請按一下「上一步」。
ReadyLabel2b=按一下「安裝」繼續安裝。
ReadyMemoUserInfo=使用者資訊：
ReadyMemoDir=目標位置：
ReadyMemoType=安裝類型：
ReadyMemoComponents=已選元件：
ReadyMemoGroup=開始功能表資料夾：
ReadyMemoTasks=附加工作：

; *** TDownloadWizardPage wizard page and DownloadTemporaryFile
DownloadingLabel2=正在下載檔案...
ButtonStopDownload=停止下載(&S)
StopDownload=確定要停止下載嗎？
ErrorDownloadAborted=下載已中止
ErrorDownloadFailed=下載失敗：%1 %2
ErrorDownloadSizeFailed=取得大小失敗：%1 %2
ErrorProgress=進度無效：%1 / %2
ErrorFileSize=檔案大小無效：預期 %1，實際為 %2

; *** TExtractionWizardPage wizard page and ExtractArchive
ExtractingLabel=正在解壓縮檔案...
ButtonStopExtraction=停止解壓縮(&S)
StopExtraction=確定要停止解壓縮嗎？
ErrorExtractionAborted=解壓縮已中止
ErrorExtractionFailed=解壓縮失敗：%1

; *** Archive extraction failure details
ArchiveIncorrectPassword=密碼不正確
ArchiveIsCorrupted=壓縮檔已損毀
ArchiveUnsupportedFormat=不支援該壓縮檔格式

; *** "Preparing to Install" wizard page
WizardPreparing=正在準備安裝
PreparingDesc=安裝程式正在準備於您的電腦上安裝 [name]。
PreviousInstallNotCompleted=上一次程式安裝或移除尚未完成。您需要重新啟動電腦才能完成那次安裝。%n%n重新啟動後，請再次執行安裝程式以完成 [name] 的安裝。
CannotContinue=安裝程式無法繼續。請按一下「取消」退出。
ApplicationsFound=下列應用程式正在使用安裝程式需要更新的檔案。建議允許安裝程式自動關閉這些應用程式。
ApplicationsFound2=下列應用程式正在使用安裝程式需要更新的檔案。建議允許安裝程式自動關閉這些應用程式。安裝完成後，安裝程式會嘗試重新啟動這些應用程式。
CloseApplications=自動關閉這些應用程式(&A)
DontCloseApplications=不要關閉這些應用程式(&D)
ErrorCloseApplications=安裝程式無法自動關閉所有應用程式。建議您在繼續之前，手動關閉所有正在使用待更新檔案的應用程式。
PrepareToInstallNeedsRestart=安裝程式必須重新啟動您的電腦。重新啟動後，請再次執行安裝程式以完成 [name] 的安裝。%n%n是否立即重新啟動？

; *** "Installing" wizard page
WizardInstalling=正在安裝
InstallingLabel=請稍候，安裝程式正在將 [name] 安裝到您的電腦上。

; *** "Setup Completed" wizard page
FinishedHeadingLabel=正在完成 [name] 安裝精靈
FinishedLabelNoIcons=安裝程式已在您的電腦上完成 [name] 的安裝。
FinishedLabel=安裝程式已在您的電腦上完成 [name] 的安裝。您可以透過已建立的捷徑啟動該應用程式。
ClickFinish=按一下「完成」退出安裝程式。
FinishedRestartLabel=要完成 [name] 的安裝，安裝程式必須重新啟動您的電腦。是否立即重新啟動？
FinishedRestartMessage=要完成 [name] 的安裝，安裝程式必須重新啟動您的電腦。%n%n是否立即重新啟動？
ShowReadmeCheck=是，我想檢視 README 檔案
YesRadio=是，立即重新啟動電腦(&Y)
NoRadio=否，我稍後再重新啟動電腦(&N)
; used for example as 'Run MyProg.exe'
RunEntryExec=執行 %1
; used for example as 'View Readme.txt'
RunEntryShellExec=檢視 %1

; *** "Setup Needs the Next Disk" stuff
ChangeDiskTitle=安裝程式需要下一張磁碟
SelectDiskLabel2=請插入磁碟 %1，然後按一下「確定」。%n%n如果此磁碟上的檔案位於下方所顯示資料夾以外的位置，請輸入正確路徑或按一下「瀏覽」。
PathLabel=&Path:
FileNotInDir2=在「%2」中找不到檔案「%1」。請插入正確的磁碟或選擇其他資料夾。
SelectDirectoryLabel=請指定下一張磁碟的位置。

; *** Installation phase messages
SetupAborted=安裝尚未完成。%n%n請修正此問題後再次執行安裝程式。
AbortRetryIgnoreSelectAction=請選擇操作
AbortRetryIgnoreRetry=&Try again
AbortRetryIgnoreIgnore=&Ignore the error and continue
AbortRetryIgnoreCancel=取消安裝
RetryCancelSelectAction=請選擇操作
RetryCancelRetry=&Try again
RetryCancelCancel=取消

; *** Installation status messages
StatusClosingApplications=正在關閉應用程式...
StatusCreateDirs=正在建立目錄...
StatusExtractFiles=正在解壓縮檔案...
StatusDownloadFiles=正在下載檔案...
StatusCreateIcons=正在建立捷徑...
StatusCreateIniEntries=正在建立 INI 項目...
StatusCreateRegistryEntries=正在建立登錄項目...
StatusRegisterFiles=正在註冊檔案...
StatusSavingUninstall=正在儲存解除安裝資訊...
StatusRunProgram=正在完成安裝...
StatusRestartingApplications=正在重新啟動應用程式...
StatusRollback=正在復原變更...

; *** Misc. errors
ErrorInternal2=內部錯誤：%1
ErrorFunctionFailedNoCode=%1 failed
ErrorFunctionFailed=%1 failed; code %2
ErrorFunctionFailedWithMessage=%1 failed; code %2.%n%3
ErrorExecutingProgram=無法執行檔案：%n%1

; *** Registry errors
ErrorRegOpenKey=開啟登錄機碼時發生錯誤：%n%1\%2
ErrorRegCreateKey=建立登錄機碼時發生錯誤：%n%1\%2
ErrorRegWriteKey=寫入登錄機碼時發生錯誤：%n%1\%2

; *** INI errors
ErrorIniEntry=在檔案“%1”中建立 INI 項目時發生錯誤。

; *** File copying errors
FileAbortRetryIgnoreSkipNotRecommended=&Skip this file (not recommended)
FileAbortRetryIgnoreIgnoreNotRecommended=&Ignore the error and continue (not recommended)
SourceIsCorrupted=來源檔案已損毀
SourceDoesntExist=來源檔案“%1”不存在
SourceVerificationFailed=來源檔案驗證失敗：%1
VerificationSignatureDoesntExist=簽章檔案“%1”不存在
VerificationSignatureInvalid=簽章檔案“%1”無效
VerificationKeyNotFound=簽章檔案“%1”使用了未知金鑰
VerificationFileNameIncorrect=檔案名稱不正確
VerificationFileTagIncorrect=檔案標籤不正確
VerificationFileSizeIncorrect=檔案大小不正確
VerificationFileHashIncorrect=檔案雜湊不正確
ExistingFileReadOnly2=無法取代現有檔案，因為它被標記為唯讀。
ExistingFileReadOnlyRetry=&Remove the read-only attribute and try again
ExistingFileReadOnlyKeepExisting=&Keep the existing file
ErrorReadingExistingDest=讀取現有檔案時發生錯誤：
FileExistsSelectAction=請選擇操作
FileExists2=該檔案已存在。
FileExistsOverwriteExisting=&Overwrite the existing file
FileExistsKeepExisting=&Keep the existing file
FileExistsOverwriteOrKeepAll=&Do this for the next conflicts
ExistingFileNewerSelectAction=請選擇操作
ExistingFileNewer2=現有檔案比安裝程式要安裝的檔案更新。
ExistingFileNewerOverwriteExisting=&Overwrite the existing file
ExistingFileNewerKeepExisting=&Keep the existing file (recommended)
ExistingFileNewerOverwriteOrKeepAll=&Do this for the next conflicts
ErrorChangingAttr=變更現有檔案屬性時發生錯誤：
ErrorCreatingTemp=在目標目錄中建立檔案時發生錯誤：
ErrorReadingSource=讀取來源檔案時發生錯誤：
ErrorCopying=複製檔案時發生錯誤：
ErrorDownloading=下載檔案時發生錯誤：
ErrorExtracting=解壓縮封存檔時發生錯誤：
ErrorReplacingExistingFile=取代現有檔案時發生錯誤：
ErrorRestartReplace=重新啟動取代失敗：
ErrorRenamingTemp=重新命名目標目錄中的檔案時發生錯誤：
ErrorRegisterServer=無法註冊 DLL/OCX：%1
ErrorRegSvr32Failed=RegSvr32 執行失敗，退出代碼為 %1
ErrorRegisterTypeLib=無法註冊類型程式庫：%1

; *** Uninstall display name markings
; used for example as 'My Program (32-bit)'
UninstallDisplayNameMark=%1 (%2)
; used for example as 'My Program (32-bit, All users)'
UninstallDisplayNameMarks=%1 (%2, %3)
UninstallDisplayNameMark32Bit=32-bit
UninstallDisplayNameMark64Bit=64-bit
UninstallDisplayNameMarkAllUsers=所有使用者
UninstallDisplayNameMarkCurrentUser=目前使用者

; *** Post-installation errors
ErrorOpeningReadme=開啟 README 檔案時發生錯誤。
ErrorRestartingComputer=安裝程式無法重新啟動電腦。請手動執行。

; *** Uninstaller messages
UninstallNotFound=檔案“%1”不存在，無法解除安裝。
UninstallOpenError=無法開啟檔案“%1”，無法解除安裝
UninstallUnsupportedVer=解除安裝記錄檔“%1”的格式不受目前解除安裝程式支援，無法解除安裝
UninstallUnknownEntry=在解除安裝記錄中遇到未知項目（%1）
ConfirmUninstall=確定要完全移除 %1 及其所有元件嗎？
UninstallOnlyOnWin64=此安裝只能在 64 位元 Windows 上解除安裝。
OnlyAdminCanUninstall=只有具備系統管理員權限的使用者才能解除安裝此安裝。
UninstallStatusLabel=請稍候，%1 正在從您的電腦中移除。
UninstalledAll=%1 was successfully removed from your computer.
UninstalledMost=%1 uninstall complete.%n%nSome elements could not be removed. These can be removed manually.
UninstalledAndNeedsRestart=要完成 %1 的解除安裝，必須重新啟動您的電腦。%n%n是否立即重新啟動？
UninstallDataCorrupted="%1" file is corrupted. Cannot uninstall

; *** Uninstallation phase messages
ConfirmDeleteSharedFileTitle=刪除共用檔案？
ConfirmDeleteSharedFile2=系統偵測到下列共用檔案已不再被任何程式使用。要讓解除安裝程式刪除此共用檔案嗎？%n%n如果仍有程式正在使用此檔案，而該檔案被刪除，這些程式可能無法正常運作。如果您不確定，請選擇「否」。將該檔案保留在系統中不會造成任何損害。
SharedFileNameLabel=檔案名稱：
SharedFileLocationLabel=位置：
WizardUninstalling=解除安裝狀態
StatusUninstalling=正在解除安裝 %1...

; *** Shutdown block reasons
ShutdownBlockReasonInstallingApp=正在安裝 %1。
ShutdownBlockReasonUninstallingApp=正在解除安裝 %1。

; The custom messages below aren't used by Setup itself, but if you make
; use of them in your scripts, you'll want to translate them.

[CustomMessages]

NameAndVersion=%1 version %2
AdditionalIcons=附加捷徑：
CreateDesktopIcon=建立桌面捷徑(&D)
CreateQuickLaunchIcon=建立快速啟動捷徑(&Q)
ProgramOnTheWeb=%1 on the Web
UninstallProgram=解除安裝 %1
LaunchProgram=啟動 %1
AssocFileExtension=&Associate %1 with the %2 file extension
AssocingFileExtension=正在將 %1 與 %2 副檔名建立關聯...
AutoStartProgramGroupDescription=啟動：
AutoStartProgram=自動啟動 %1
AddonHostProgramNotFound=%1 could not be located in the folder you selected.%n%nDo you want to continue anyway?



