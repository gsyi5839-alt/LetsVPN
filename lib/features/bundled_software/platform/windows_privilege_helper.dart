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
}

/// Token elevation structure
base class TOKEN_ELEVATION extends Struct {
  @DWORD()
  external int TokenIsElevated;
}
