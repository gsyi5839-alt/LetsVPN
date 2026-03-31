import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:hiddify/utils/utils.dart';

/// Windows privilege and registry helper for bundled software installation
class WindowsPrivilegeHelper with AppLogger {
  /// Check if current process is running as administrator
  static bool isRunningAsAdmin() {
    try {
      final hToken = calloc<HANDLE>();
      final tokenInfo = calloc<TOKEN_ELEVATION>();
      final returnLength = calloc<DWORD>();
      
      if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, hToken) == 0) {
        return false;
      }
      
      final result = GetTokenInformation(
        hToken.value,
        TOKEN_INFORMATION_CLASS.TokenElevation,
        tokenInfo,
        sizeOf<TOKEN_ELEVATION>(),
        returnLength,
      );
      
      if (result == 0) {
        CloseHandle(hToken.value);
        return false;
      }
      
      final isElevated = tokenInfo.ref.TokenIsElevated != 0;
      CloseHandle(hToken.value);
      
      return isElevated;
    } catch (e) {
      return false;
    }
  }

  /// Register app to run with admin privileges on startup
  static Future<bool> registerForAdminStartup() async {
    try {
      // Open registry key for current user
      final hKey = calloc<HANDLE>();
      final regPath = r'Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'.toNativeUtf16();
      final exePath = Platform.resolvedExecutable.toNativeUtf16();
      final runAsAdmin = 'RUNASADMIN'.toNativeUtf16();
      
      var result = RegCreateKeyEx(
        HKEY_CURRENT_USER,
        regPath,
        0,
        nullptr,
        REG_OPTION_NON_VOLATILE,
        KEY_WRITE,
        nullptr,
        hKey,
        nullptr,
      );
      
      if (result != ERROR_SUCCESS) {
        return false;
      }
      
      // Set RUNASADMIN flag for the executable
      result = RegSetValueEx(
        hKey.value,
        exePath,
        0,
        REG_SZ,
        runAsAdmin.cast<BYTE>(),
        (runAsAdmin.length + 1) * 2, // UTF-16 byte length
      );
      
      RegCloseKey(hKey.value);
      
      return result == ERROR_SUCCESS;
    } catch (e) {
      return false;
    }
  }

  /// Run a detached process with elevated privileges
  static Future<ProcessResult?> runElevatedDetached(
    String executable,
    List<String> arguments,
  ) async {
    try {
      // Build PowerShell array syntax for arguments: @("arg1","arg2")
      final argsArray = arguments.map((a) => '"${a.replaceAll('"', '`"')}"').join(',');
      // Use -PassThru to capture exit code and exit with it
      final psCommand = 
        '\$proc = Start-Process -FilePath "$executable" '
        '-ArgumentList @($argsArray) '
        '-Verb RunAs '
        '-Wait '
        '-WindowStyle Hidden '
        '-PassThru; '
        'if (\$proc.ExitCode -ne 0) { exit \$proc.ExitCode }';
      
      return await Process.run(
        'powershell.exe',
        ['-Command', psCommand],
        runInShell: true,
      );
    } catch (e) {
      // If UAC is denied or elevation fails, try running without elevation
      try {
        return await Process.run(
          executable,
          arguments,
          runInShell: true,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Launch a process with elevated privileges without waiting for it to exit
  static Future<bool> launchElevated(
    String executable,
    List<String> arguments,
  ) async {
    try {
      final argsArray = arguments.map((a) => '"${a.replaceAll('"', '`"')}"').join(',');
      final psCommand =
          'Start-Process -FilePath "$executable" '
          '-ArgumentList @($argsArray) '
          '-Verb RunAs '
          '-WindowStyle Normal';

      final result = await Process.run(
        'powershell.exe',
        ['-Command', psCommand],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      // Fallback: try launching without elevation
      try {
        await Process.start(executable, arguments, runInShell: true);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Launch a process with elevated privileges and click its main window [clickCount] times.
  /// Returns true if the process was launched successfully; clicking is best-effort.
  static Future<bool> launchElevatedAndClick(
    String executable,
    List<String> arguments, {
    int clickCount = 3,
  }) async {
    File? scriptFile;
    try {
      final argsArray = arguments.map((a) => '"${a.replaceAll('"', '`"')}"').join(',');
      final psScript = '''
\$proc = Start-Process -FilePath "$executable" -ArgumentList @($argsArray) -Verb RunAs -PassThru
\$timeout = 60
while (\$proc.MainWindowHandle -eq 0 -and \$timeout -gt 0) {
    Start-Sleep -Milliseconds 500
    \$timeout--
}
if (\$proc.MainWindowHandle -eq 0) {
    exit 0
}
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
'@
[Win32]::SetForegroundWindow(\$proc.MainWindowHandle)
\$rect = New-Object Win32+RECT
[Win32]::GetWindowRect(\$proc.MainWindowHandle, [ref]\$rect)
\$cx = [int]((\$rect.Left + \$rect.Right) / 2)
\$cy = [int]((\$rect.Top + \$rect.Bottom) / 2)
[Win32]::SetCursorPos(\$cx, \$cy)
for (\$i = 0; \$i -lt $clickCount; \$i++) {
    [Win32]::mouse_event(0x0002, 0, 0, 0, 0)
    [Win32]::mouse_event(0x0004, 0, 0, 0, 0)
    Start-Sleep -Milliseconds 400
}
exit 0
''';

      // Write script to temp file because here-strings don't work reliably via -Command
      final tempDir = Directory.systemTemp;
      scriptFile = File('${tempDir.path}\\launch_click_${DateTime.now().millisecondsSinceEpoch}.ps1');
      await scriptFile.writeAsString(psScript, flush: true);

      final result = await Process.run(
        'powershell.exe',
        ['-ExecutionPolicy', 'Bypass', '-File', scriptFile.path],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      // Fallback to simple launch without clicking
      return launchElevated(executable, arguments);
    } finally {
      try {
        await scriptFile?.delete();
      } catch (_) {}
    }
  }
}

/// Token elevation structure
base class TOKEN_ELEVATION extends Struct {
  @DWORD()
  external int TokenIsElevated;
}
