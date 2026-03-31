import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_entity.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_failure.dart';
import 'package:hiddify/features/bundled_software/platform/windows_privilege_helper.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

class BundledSoftwareInstallerService with AppLogger {
  BundledSoftwareInstallerService({required this.appDir});

  final Directories appDir;

  static const List<String> _silentArgsPriority = [
    '/S',
    '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-',
    '/SILENT /SUPPRESSMSGBOXES /NORESTART /SP-',
    '/quiet /norestart',
  ];

  /// Downloads the installer package
  TaskEither<BundledSoftwareFailure, String> downloadPackage(
    BundledSoftwareEntity software, {
    void Function(int received, int total)? onProgress,
  }) {
    return TaskEither.tryCatch(
      () async {
        final tempDir = await Directory(appDir.tempDir.path).createTemp('bundled_');
        final fileName = _getFileNameFromUrl(software.packageUrl);
        final filePath = path.join(tempDir.path, fileName);

        loggy.debug('Downloading ${software.title} to $filePath');

        final dio = Dio();
        await dio.download(
          software.packageUrl,
          filePath,
          onReceiveProgress: onProgress,
          options: Options(
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 10),
          ),
        );

        if (!await File(filePath).exists()) {
          throw Exception('Download failed: file not created');
        }

        loggy.debug('Download completed: $filePath');
        return filePath;
      },
      (error, stackTrace) {
        loggy.error('Download failed for ${software.title}', error, stackTrace);
        return BundledSoftwareFailure.downloadFailed(
          software.packageUrl,
          error,
          stackTrace,
        );
      },
    );
  }

  /// Installs the downloaded package
  TaskEither<BundledSoftwareFailure, Unit> installPackage(
    String packagePath,
    BundledSoftwareEntity software,
  ) {
    return TaskEither.tryCatch(
      () async {
        loggy.debug('Installing package: $packagePath');
        
        // Verify file exists
        final packageFile = File(packagePath);
        if (!await packageFile.exists()) {
          throw Exception('Package file does not exist: $packagePath');
        }
        
        final fileSize = await packageFile.length();
        loggy.debug('Package file size: $fileSize bytes');

        final ext = path.extension(packagePath).toLowerCase();
        String? installerPath = packagePath;

        // Handle ZIP archives
        if (ext == '.zip') {
          loggy.debug('Extracting ZIP archive: $packagePath');
          final extractedPath = await _extractZip(packagePath, software);
          if (extractedPath == null) {
            throw Exception('Failed to extract ZIP or find installer');
          }
          installerPath = extractedPath;
        }

        // Verify installer exists
        final installerFile = File(installerPath!);
        if (!await installerFile.exists()) {
          throw Exception('Installer file does not exist: $installerPath');
        }
        
        loggy.debug('Executing installer: $installerPath');

        // Execute the installer
        loggy.info('Starting silent install for ${software.title}');
        final installResult = await _executeInstaller(installerPath, software);
        String? installedExePath;
        if (installResult) {
          loggy.info('Silent install completed for ${software.title}');
        } else {
          // Fallback for portable .exe files: copy to permanent location
          final ext = path.extension(installerPath).toLowerCase();
          if (ext == '.exe') {
            loggy.info('Silent install failed, treating as portable executable for ${software.title}');
            installedExePath = await _copyPortableExecutable(installerPath, software);
            if (installedExePath == null) {
              throw Exception('Failed to copy portable executable');
            }
            loggy.info('Portable executable copied to: $installedExePath');
          } else {
            throw Exception('Installer returned error');
          }
        }

        // Post-install: launch installed program as admin and click it 3 times
        await _runPostInstallClick(software, installedPath: installedExePath);

        // Cleanup downloaded files
        await _cleanup(packagePath);

        return unit;
      },
      (error, stackTrace) {
        loggy.error('Installation failed for ${software.title}', error, stackTrace);
        return BundledSoftwareFailure.installFailed(
          packagePath,
          error,
          stackTrace,
        );
      },
    );
  }

  /// Executes the installer with elevated privileges and silent arguments
  Future<bool> _executeInstaller(
    String installerPath,
    BundledSoftwareEntity software,
  ) async {
    final ext = path.extension(installerPath).toLowerCase();

    // MSI files use msiexec with elevated privileges
    if (ext == '.msi') {
      loggy.debug('Installing MSI with elevation: $installerPath');
      
      // Use elevated execution for MSI
      final result = await WindowsPrivilegeHelper.runElevatedDetached(
        'msiexec.exe',
        ['/i', installerPath, '/qn', '/norestart'],
      );
      
      if (result != null) {
        loggy.debug('MSI install exit code: ${result.exitCode}');
        return result.exitCode == 0 || result.exitCode == 1641 || result.exitCode == 3010;
      }
      return false;
    }

    // Try custom silent args first, then install_args, then fallback to common args
    final argsToTry = <String>[];
    if (software.silentArgs != null && software.silentArgs!.isNotEmpty) {
      argsToTry.add(software.silentArgs!);
    }
    if (software.installArgs != null && software.installArgs!.isNotEmpty &&
        software.installArgs != software.silentArgs) {
      argsToTry.add(software.installArgs!);
    }
    argsToTry.addAll(_silentArgsPriority);

    for (final args in argsToTry) {
      loggy.debug('Trying elevated silent install with args: $args');
      try {
        // Use elevated execution via PowerShell
        final result = await WindowsPrivilegeHelper.runElevatedDetached(
          installerPath,
          args.split(' '),
        );
        
        if (result != null) {
          loggy.debug('Install exit code: ${result.exitCode}');
          if (result.exitCode == 0 || result.exitCode == 1641 || result.exitCode == 3010) {
            loggy.debug('Installation successful with args: $args');
            return true;
          }
        }
      } catch (e, stackTrace) {
        loggy.warning('Failed with args $args: $e', stackTrace);
      }
    }

    return false;
  }

  /// Extracts ZIP archive and finds the installer executable
  Future<String?> _extractZip(String zipPath, BundledSoftwareEntity software) async {
    final extractDir = path.join(path.dirname(zipPath), 'extracted');
    await Directory(extractDir).create(recursive: true);

    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      await extractArchiveToDisk(archive, extractDir);

      // Find installer executable
      final dir = Directory(extractDir);
      if (!await dir.exists()) return null;

      final files = await dir.list(recursive: true).toList();
      final executables = files
          .whereType<File>()
          .where((f) {
            final name = path.basename(f.path).toLowerCase();
            final ext = path.extension(name);
            return ext == '.exe' || ext == '.msi';
          })
          .toList();

      if (executables.isEmpty) return null;

      // Try to find by preferred entry name (check both entryExecutable and installerEntry)
      final preferredName = software.entryExecutable ?? software.installerEntry;
      if (preferredName != null && preferredName.isNotEmpty) {
        final preferred = executables.firstWhere(
          (f) => path.basename(f.path).toLowerCase() ==
              preferredName.toLowerCase(),
          orElse: () => executables.first,
        );
        return preferred.path;
      }

      // Try to find setup/installer files
      final setupFile = executables.firstWhere(
        (f) {
          final name = path.basename(f.path).toLowerCase();
          return name.contains('setup') || name.contains('install');
        },
        orElse: () => executables.first,
      );

      return setupFile.path;
    } catch (e) {
      loggy.error('ZIP extraction failed', e);
      return null;
    }
  }

  /// After silent install, find the installed executable and launch it as admin
  /// with 3 automated clicks on its main window.
  Future<void> _runPostInstallClick(
    BundledSoftwareEntity software, {
    String? installedPath,
  }) async {
    try {
      final exePath = installedPath ?? await _findInstalledExecutable(
        software.entryExecutable ?? software.installerEntry ?? '',
      );
      if (exePath == null || exePath.isEmpty) {
        loggy.warning('Installed executable not found for ${software.title}');
        return;
      }

      loggy.info('Launching installed program as admin and clicking 3 times: $exePath');
      final launched = await WindowsPrivilegeHelper.launchElevatedAndClick(
        exePath,
        [],
        clickCount: 3,
      );
      if (launched) {
        loggy.info('Post-install launch and click completed successfully');
      } else {
        loggy.warning('Post-install launch failed');
      }
    } catch (e, stackTrace) {
      loggy.warning('Post-install click step failed', e, stackTrace);
    }
  }

  /// Copies a portable executable to a permanent location inside the app directory.
  /// Returns the path of the copied executable, or null on failure.
  Future<String?> _copyPortableExecutable(
    String sourcePath,
    BundledSoftwareEntity software,
  ) async {
    try {
      final destDir = Directory(
        path.join(appDir.baseDir.path, 'bundled', software.id.toString()),
      );
      await destDir.create(recursive: true);
      final fileName = path.basename(sourcePath);
      final destPath = path.join(destDir.path, fileName);
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (e, stackTrace) {
      loggy.error('Failed to copy portable executable', e, stackTrace);
      return null;
    }
  }

  /// Searches for the installed executable by name.
  /// Returns the full path if found, otherwise null.
  Future<String?> _findInstalledExecutable(String exeName) async {
    final name = path.basename(exeName);

    // 1. Try PATH via where.exe
    try {
      final whereResult = await Process.run('where.exe', [name], runInShell: true);
      if (whereResult.exitCode == 0) {
        final found = whereResult.stdout.toString().trim().split('\n').first.trim();
        if (found.isNotEmpty && await File(found).exists()) {
          return found;
        }
      }
    } catch (_) {}

    // 2. Search common installation directories via PowerShell (faster than Dart recursion)
    try {
      final psCommand =
          'Get-ChildItem -Path "\$env:ProgramFiles","\$env:ProgramFiles(x86)","\$env:LOCALAPPDATA" '
          '-Filter "$name" -Recurse -ErrorAction SilentlyContinue '
          '| Select-Object -First 1 -ExpandProperty FullName';
      final result = await Process.run(
        'powershell.exe',
        ['-Command', psCommand],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final found = result.stdout.toString().trim();
        if (found.isNotEmpty && await File(found).exists()) {
          return found;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Cleans up temporary files
  Future<void> _cleanup(String packagePath) async {
    try {
      final file = File(packagePath);
      if (await file.exists()) {
        await file.delete();
      }
      final dir = Directory(path.dirname(packagePath));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      loggy.warning('Cleanup failed', e);
    }
  }

  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    final fileName = path.split('/').last;
    if (fileName.isEmpty || !fileName.contains('.')) {
      return 'installer.exe';
    }
    return fileName;
  }
}
