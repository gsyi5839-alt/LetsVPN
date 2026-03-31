import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_failure.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_response.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:http/http.dart' as http;

/// 桌面端 API 服务
/// 基于文档: https://lrtsvpn.com/desktop/api/v1
class DesktopApiService with AppLogger {
  DesktopApiService();

  static const String _baseUrl = 'https://lrtsvpn.com';
  static const String _downloadsEndpoint = '/desktop/api/v1/downloads';
  static const String _checkEndpoint = '/desktop/api/v1/install/check';
  static const String _confirmEndpoint = '/desktop/api/v1/install/confirm';
  static const String _eventsBatchEndpoint = '/desktop/api/v1/events/batch';

  /// 获取下载清单
  /// GET /desktop/api/v1/downloads
  TaskEither<BundledSoftwareFailure, DownloadsResponse> fetchDownloads() {
    return TaskEither.tryCatch(
      () async {
        final response = await http.get(
          Uri.parse('$_baseUrl$_downloadsEndpoint'),
        );

        if (response.statusCode != 200) {
          loggy.warning('Failed to fetch downloads: ${response.statusCode}');
          throw Exception('HTTP ${response.statusCode}');
        }

        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (jsonData['ret'] != 1) {
          throw Exception(jsonData['msg'] ?? 'API error');
        }
        
        final data = DownloadsResponse.fromJson(jsonData['data'] as Map<String, dynamic>);
        loggy.debug('Fetched downloads for ${data.downloads?.keys.join(", ") ?? "none"}');
        return data;
      },
      (error, stackTrace) {
        loggy.error('Error fetching downloads', error, stackTrace);
        return BundledSoftwareFailure.networkError(error, stackTrace);
      },
    );
  }

  /// 安装核对 - 检查需要安装的包
  /// POST /desktop/api/v1/install/check
  TaskEither<BundledSoftwareFailure, BundledSoftwareResponse> fetchPackageList({
    String? deviceId,
    Map<String, dynamic>? installedPackages,
  }) {
    return TaskEither.tryCatch(
      () async {
        final body = <String, dynamic>{
          'platform': 'windows',
        };
        if (installedPackages != null && installedPackages.isNotEmpty) {
          body['installed_packages'] = installedPackages;
        }

        final response = await http.post(
          Uri.parse('$_baseUrl$_checkEndpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) {
          loggy.warning('Failed to fetch package list: ${response.statusCode}');
          throw Exception('HTTP ${response.statusCode}');
        }

        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (jsonData['ret'] != 1) {
          throw Exception(jsonData['msg'] ?? 'API error');
        }
        
        final data = BundledSoftwareResponse.fromJson(jsonData);
        loggy.debug('Fetched ${data.data?.needsInstallCount ?? 0} packages to install');
        return data;
      },
      (error, stackTrace) {
        loggy.error('Error fetching package list', error, stackTrace);
        return BundledSoftwareFailure.networkError(error, stackTrace);
      },
    );
  }

  /// 安装完成上报
  /// POST /desktop/api/v1/install/confirm
  TaskEither<BundledSoftwareFailure, Unit> confirmInstall({
    required String deviceId,
    required int packageId,
    required String versionId,
    String status = 'success',
    String? message,
    String? userId,
    String? clientVersion,
  }) {
    return TaskEither.tryCatch(
      () async {
        final body = <String, dynamic>{
          'device_id': deviceId,
          'package_id': packageId,
          'version_id': versionId,
          'status': status,
          'platform': 'windows',
          'install_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        };
        
        if (message != null) body['message'] = message;
        if (userId != null) body['user_id'] = userId;
        if (clientVersion != null) body['client_version'] = clientVersion;

        final response = await http.post(
          Uri.parse('$_baseUrl$_confirmEndpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) {
          loggy.warning('Failed to confirm install: ${response.statusCode}');
          throw Exception('HTTP ${response.statusCode}');
        }

        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonData['ret'] != 1) {
          throw Exception(jsonData['msg'] ?? 'Confirm failed');
        }
        
        loggy.debug('Install confirmed: package=$packageId version=$versionId status=$status');
        return unit;
      },
      (error, stackTrace) {
        loggy.error('Error confirming install', error, stackTrace);
        return BundledSoftwareFailure.networkError(error, stackTrace);
      },
    );
  }

  /// 批量事件上报
  /// POST /desktop/api/v1/events/batch
  TaskEither<BundledSoftwareFailure, EventsBatchResponse> sendEventsBatch({
    required List<Map<String, dynamic>> events,
    String? deviceId,
    String? userId,
    String? clientVersion,
  }) {
    return TaskEither.tryCatch(
      () async {
        final body = <String, dynamic>{
          'events': events,
          'platform': 'windows',
        };
        
        if (deviceId != null) body['device_id'] = deviceId;
        if (userId != null) body['user_id'] = userId;
        if (clientVersion != null) body['client_version'] = clientVersion;

        final response = await http.post(
          Uri.parse('$_baseUrl$_eventsBatchEndpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) {
          loggy.warning('Failed to send events batch: ${response.statusCode}');
          throw Exception('HTTP ${response.statusCode}');
        }

        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (jsonData['ret'] != 1) {
          throw Exception(jsonData['msg'] ?? 'Events batch failed');
        }
        
        final data = EventsBatchResponse.fromJson(jsonData['data'] as Map<String, dynamic>);
        loggy.debug('Events batch sent: saved=${data.saved}, duplicate=${data.duplicate}, failed=${data.failed}');
        return data;
      },
      (error, stackTrace) {
        loggy.error('Error sending events batch', error, stackTrace);
        return BundledSoftwareFailure.networkError(error, stackTrace);
      },
    );
  }

  /// 快捷方法：上报单个事件（包装为批量）
  TaskEither<BundledSoftwareFailure, EventsBatchResponse> sendEvent({
    required String eventType,
    String? deviceId,
    String? userId,
    String? clientVersion,
    int? adId,
    Map<String, dynamic>? extra,
  }) {
    final event = <String, dynamic>{
      'event_type': eventType,
      'event_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    
    if (deviceId != null) event['device_id'] = deviceId;
    if (userId != null) event['user_id'] = userId;
    if (adId != null) event['ad_id'] = adId;
    if (extra != null) event['extra'] = extra;

    return sendEventsBatch(
      events: [event],
      deviceId: deviceId,
      userId: userId,
      clientVersion: clientVersion,
    );
  }
}

/// 下载清单响应
class DownloadsResponse {
  final Map<String, List<DownloadInfo>>? downloads;
  final String? pushEndpoint;
  final String? resolveEndpoint;

  DownloadsResponse({
    this.downloads,
    this.pushEndpoint,
    this.resolveEndpoint,
  });

  factory DownloadsResponse.fromJson(Map<String, dynamic> json) {
    final downloadsJson = json['downloads'] as Map<String, dynamic>?;
    Map<String, List<DownloadInfo>>? downloads;
    
    if (downloadsJson != null) {
      downloads = {};
      downloadsJson.forEach((platform, items) {
        if (items is List) {
          downloads![platform] = items
              .map((e) => DownloadInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      });
    }

    return DownloadsResponse(
      downloads: downloads,
      pushEndpoint: json['push_endpoint'] as String?,
      resolveEndpoint: json['resolve_endpoint'] as String?,
    );
  }
}

/// 单个下载信息
class DownloadInfo {
  final String? platform;
  final String? channel;
  final String? filename;
  final String? downloadUrl;
  final String? bridgeUrl;

  DownloadInfo({
    this.platform,
    this.channel,
    this.filename,
    this.downloadUrl,
    this.bridgeUrl,
  });

  factory DownloadInfo.fromJson(Map<String, dynamic> json) {
    return DownloadInfo(
      platform: json['platform'] as String?,
      channel: json['channel'] as String?,
      filename: json['filename'] as String?,
      downloadUrl: json['download_url'] as String?,
      bridgeUrl: json['bridge_url'] as String?,
    );
  }
}

/// 批量事件上报响应
class EventsBatchResponse {
  final int saved;
  final int duplicate;
  final int failed;
  final List<EventItemResult>? items;

  EventsBatchResponse({
    required this.saved,
    required this.duplicate,
    required this.failed,
    this.items,
  });

  factory EventsBatchResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>?;
    
    return EventsBatchResponse(
      saved: json['saved'] as int? ?? 0,
      duplicate: json['duplicate'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      items: itemsJson?.map((e) => EventItemResult.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// 单个事件上报结果
class EventItemResult {
  final bool saved;
  final int? id;
  final String? normalizedType;
  final int index;

  EventItemResult({
    required this.saved,
    this.id,
    this.normalizedType,
    required this.index,
  });

  factory EventItemResult.fromJson(Map<String, dynamic> json) {
    return EventItemResult(
      saved: json['saved'] as bool? ?? false,
      id: json['id'] as int?,
      normalizedType: json['normalized_type'] as String?,
      index: json['index'] as int? ?? 0,
    );
  }
}
