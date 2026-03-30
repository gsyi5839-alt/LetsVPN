import 'dart:convert';

import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_entity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final bundledSoftwareLocalDataSourceProvider = Provider<BundledSoftwareLocalDataSource>(
  (ref) => BundledSoftwareLocalDataSource(
    prefs: ref.watch(sharedPreferencesProvider).requireValue,
  ),
);

class BundledSoftwareLocalDataSource {
  BundledSoftwareLocalDataSource({required this.prefs});

  final SharedPreferences prefs;

  static const String _installedSoftwareKey = 'bundled_software_installed';
  static const String _visitorIdKey = 'bundled_software_visitor_id';
  static const String _lastCheckKey = 'bundled_software_last_check';

  String? getVisitorId() => prefs.getString(_visitorIdKey);

  Future<void> setVisitorId(String visitorId) async {
    await prefs.setString(_visitorIdKey, visitorId);
  }

  DateTime? getLastCheck() {
    final timestamp = prefs.getInt(_lastCheckKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> setLastCheck(DateTime time) async {
    await prefs.setInt(_lastCheckKey, time.millisecondsSinceEpoch);
  }

  List<BundledSoftwareEntity> getInstalledSoftware() {
    final json = prefs.getString(_installedSoftwareKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => BundledSoftwareEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveInstalledSoftware(List<BundledSoftwareEntity> software) async {
    final json = jsonEncode(software.map((e) => e.toJson()).toList());
    await prefs.setString(_installedSoftwareKey, json);
  }

  Future<void> updateSoftwareStatus(
    int id, {
    required BundledSoftwareStatus status,
    String? installedVersion,
    DateTime? installedAt,
    String? errorMessage,
  }) async {
    final software = getInstalledSoftware();
    final index = software.indexWhere((s) => s.id == id);
    
    if (index >= 0) {
      final updated = software[index].copyWith(
        status: status,
        installedVersion: installedVersion ?? software[index].installedVersion,
        installedAt: installedAt ?? software[index].installedAt,
        errorMessage: errorMessage,
      );
      software[index] = updated;
      await saveInstalledSoftware(software);
    }
  }

  Future<void> addOrUpdateSoftware(BundledSoftwareEntity software) async {
    final list = getInstalledSoftware();
    final index = list.indexWhere((s) => s.id == software.id);
    
    if (index >= 0) {
      list[index] = software;
    } else {
      list.add(software);
    }
    await saveInstalledSoftware(list);
  }

  bool needsUpdate(BundledSoftwareEntity remote) {
    final local = getInstalledSoftware().firstWhere(
      (s) => s.id == remote.id,
      orElse: () => remote.copyWith(status: BundledSoftwareStatus.pending),
    );

    // No previous installation
    if (local.status != BundledSoftwareStatus.installSuccess) {
      return true;
    }

    // Version changed (compare versionId, e.g. "20260330")
    if (remote.versionId != null && remote.versionId != local.installedVersion) {
      return true;
    }

    // Package URL changed (implies new version)
    if (remote.packageUrl != local.packageUrl) {
      return true;
    }

    return false;
  }

  Future<void> clear() async {
    await prefs.remove(_installedSoftwareKey);
    await prefs.remove(_visitorIdKey);
    await prefs.remove(_lastCheckKey);
  }
}
