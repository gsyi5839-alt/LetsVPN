import 'package:freezed_annotation/freezed_annotation.dart';

part 'bundled_software_failure.freezed.dart';

@freezed
class BundledSoftwareFailure with _$BundledSoftwareFailure {
  const factory BundledSoftwareFailure.unexpected([
    Object? error,
    StackTrace? stackTrace,
  ]) = _BundledSoftwareUnexpectedFailure;

  const factory BundledSoftwareFailure.networkError([
    Object? error,
    StackTrace? stackTrace,
  ]) = _BundledSoftwareNetworkFailure;

  const factory BundledSoftwareFailure.downloadFailed(
    String url, [
    Object? error,
    StackTrace? stackTrace,
  ]) = _BundledSoftwareDownloadFailure;

  const factory BundledSoftwareFailure.installFailed(
    String executable, [
    Object? error,
    StackTrace? stackTrace,
  ]) = _BundledSoftwareInstallFailure;

  const factory BundledSoftwareFailure.invalidResponse([
    Object? error,
    StackTrace? stackTrace,
  ]) = _BundledSoftwareInvalidResponseFailure;
}
