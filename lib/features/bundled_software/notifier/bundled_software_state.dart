import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_entity.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_failure.dart';

part 'bundled_software_state.freezed.dart';

@freezed
class BundledSoftwareState with _$BundledSoftwareState {
  const factory BundledSoftwareState.initial() = BundledSoftwareStateInitial;
  
  const factory BundledSoftwareState.loading() = BundledSoftwareStateLoading;
  
  const factory BundledSoftwareState.loaded(
    List<BundledSoftwareEntity> software, {
    @Default(false) bool hasUpdates,
    @Default(0) int pendingCount,
    @Default(0) int updateAvailableCount,
  }) = BundledSoftwareStateLoaded;
  
  const factory BundledSoftwareState.installing(
    List<BundledSoftwareEntity> software,
    BundledSoftwareEntity current,
  ) = BundledSoftwareStateInstalling;
  
  const factory BundledSoftwareState.error(BundledSoftwareFailure failure) = BundledSoftwareStateError;
}

extension BundledSoftwareStateX on BundledSoftwareState {
  bool get isLoading => this is BundledSoftwareStateLoading;
  bool get isInstalling => this is BundledSoftwareStateInstalling;
  bool get hasError => this is BundledSoftwareStateError;
  
  List<BundledSoftwareEntity> get softwareList => maybeMap(
        loaded: (s) => s.software,
        installing: (s) => s.software,
        orElse: () => [],
      );
}
