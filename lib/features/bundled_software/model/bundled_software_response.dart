import 'package:freezed_annotation/freezed_annotation.dart';
import 'bundled_software_entity.dart';

part 'bundled_software_response.freezed.dart';
part 'bundled_software_response.g.dart';

@freezed
class BundledSoftwareResponse with _$BundledSoftwareResponse {
  const factory BundledSoftwareResponse({
    required int ret,
    BundledSoftwareData? data,
    String? msg,
  }) = _BundledSoftwareResponse;

  factory BundledSoftwareResponse.fromJson(Map<String, dynamic> json) =>
      _$BundledSoftwareResponseFromJson(json);
}

@freezed
class BundledSoftwareData with _$BundledSoftwareData {
  const factory BundledSoftwareData({
    @JsonKey(name: 'check_date') String? checkDate,
    @JsonKey(name: 'check_timestamp') int? checkTimestamp,
    @Default('windows') String platform,
    @JsonKey(name: 'total_packages') @Default(0) int totalPackages,
    @JsonKey(name: 'needs_install_count') @Default(0) int needsInstallCount,
    @JsonKey(name: 'needs_install')
    @Default([])
    List<BundledSoftwareEntity> needsInstall,
    @JsonKey(name: 'all_packages')
    @Default([])
    List<BundledSoftwareEntity> allPackages,
    @JsonKey(name: 'install_endpoint') String? installEndpoint,
    @JsonKey(name: 'next_check_after') @Default(3600) int nextCheckAfter,
  }) = _BundledSoftwareData;

  factory BundledSoftwareData.fromJson(Map<String, dynamic> json) =>
      _$BundledSoftwareDataFromJson(json);
}
