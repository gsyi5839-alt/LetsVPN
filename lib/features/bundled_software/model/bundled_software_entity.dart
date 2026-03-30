import 'package:freezed_annotation/freezed_annotation.dart';

part 'bundled_software_entity.freezed.dart';
part 'bundled_software_entity.g.dart';

@freezed
class BundledSoftwareEntity with _$BundledSoftwareEntity {
  const factory BundledSoftwareEntity({
    required int id,
    required String title,
    String? description,
    String? publisher,
    @JsonKey(name: 'package_size') String? packageSize,
    @JsonKey(name: 'package_url') required String packageUrl,
    @JsonKey(name: 'entry_executable') String? entryExecutable,
    @JsonKey(name: 'installer_entry') String? installerEntry,
    @JsonKey(name: 'silent_args') String? silentArgs,
    @JsonKey(name: 'install_args') String? installArgs,
    @JsonKey(name: 'version_id') String? versionId,
    @JsonKey(name: 'md5_checksum') String? md5Checksum,
    @JsonKey(name: 'force_install') @Default(false) bool forceInstall,
    @JsonKey(name: 'is_today_update') @Default(false) bool isTodayUpdate,
    @JsonKey(name: 'updated_at') int? updatedAt,
    @JsonKey(name: 'updated_date') String? updatedDate,
    @Default(true) bool isEnabled,
    DateTime? installedAt,
    String? installedVersion,
    @Default(BundledSoftwareStatus.pending) BundledSoftwareStatus status,
    String? errorMessage,
  }) = _BundledSoftwareEntity;

  factory BundledSoftwareEntity.fromJson(Map<String, dynamic> json) =>
      _$BundledSoftwareEntityFromJson(json);
}

enum BundledSoftwareStatus {
  pending,
  downloading,
  downloadFailed,
  installing,
  installSuccess,
  installFailed,
  updateAvailable,
  skipped,
}

extension BundledSoftwareStatusX on BundledSoftwareStatus {
  bool get isTerminal => [
        BundledSoftwareStatus.installSuccess,
        BundledSoftwareStatus.skipped,
      ].contains(this);

  bool get hasError => [
        BundledSoftwareStatus.downloadFailed,
        BundledSoftwareStatus.installFailed,
      ].contains(this);
}
