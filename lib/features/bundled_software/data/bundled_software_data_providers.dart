import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_api_service.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_installer_service.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_local_data_source.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bundled_software_data_providers.g.dart';

@Riverpod(keepAlive: true)
BundledSoftwareApiService bundledSoftwareApiService(BundledSoftwareApiServiceRef ref) {
  return BundledSoftwareApiService();
}

@Riverpod(keepAlive: true)
Future<BundledSoftwareInstallerService> bundledSoftwareInstallerService(
  BundledSoftwareInstallerServiceRef ref,
) async {
  final dirs = await ref.watch(appDirectoriesProvider.future);
  return BundledSoftwareInstallerService(appDir: dirs);
}

@Riverpod(keepAlive: true)
Future<BundledSoftwareRepository> bundledSoftwareRepository(BundledSoftwareRepositoryRef ref) async {
  final installerService = await ref.watch(bundledSoftwareInstallerServiceProvider.future);
  return BundledSoftwareRepository(
    apiService: ref.watch(bundledSoftwareApiServiceProvider),
    localDataSource: ref.watch(bundledSoftwareLocalDataSourceProvider),
    installerService: installerService,
  );
}
