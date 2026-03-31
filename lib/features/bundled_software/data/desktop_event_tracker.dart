import 'dart:async';
import 'dart:collection';

import 'package:hiddify/features/bundled_software/data/desktop_api_service.dart';
import 'package:hiddify/utils/utils.dart';

/// 桌面端事件跟踪器
/// 用于批量收集事件并定时/定量上报
class DesktopEventTracker with AppLogger {
  DesktopEventTracker({
    required this.apiService,
    this.deviceId,
    this.userId,
    this.clientVersion,
  });

  final DesktopApiService apiService;
  final String? deviceId;
  final String? userId;
  final String? clientVersion;

  // 事件队列
  final Queue<Map<String, dynamic>> _eventQueue = Queue();
  
  // 定时器
  Timer? _flushTimer;
  
  // 配置
  static const int _maxBatchSize = 200; // 单次最大200条
  static const Duration _flushInterval = Duration(minutes: 5); // 每5分钟上报一次
  static const int _maxQueueSize = 500; // 队列最大容量

  /// 启动定时上报
  void start() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
    loggy.debug('Event tracker started');
  }

  /// 停止定时上报
  void stop() {
    _flushTimer?.cancel();
    _flushTimer = null;
    loggy.debug('Event tracker stopped');
  }

  /// 追踪事件
  void track({
    required String eventType,
    int? adId,
    Map<String, dynamic>? extra,
    int? eventTime,
  }) {
    final event = <String, dynamic>{
      'event_type': eventType,
      'event_time': eventTime ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    if (deviceId != null) event['device_id'] = deviceId;
    if (userId != null) event['user_id'] = userId;
    if (adId != null) event['ad_id'] = adId;
    if (extra != null) event['extra'] = extra;

    _eventQueue.add(event);
    loggy.debug('Event tracked: $eventType');

    // 队列满时立即上报
    if (_eventQueue.length >= _maxBatchSize) {
      flush();
    }

    // 防止内存溢出
    if (_eventQueue.length > _maxQueueSize) {
      loggy.warning('Event queue overflow, dropping oldest events');
      while (_eventQueue.length > _maxQueueSize - _maxBatchSize) {
        _eventQueue.removeFirst();
      }
    }
  }

  /// 立即上报所有事件
  Future<void> flush() async {
    if (_eventQueue.isEmpty) return;

    final events = <Map<String, dynamic>>[];
    while (_eventQueue.isNotEmpty && events.length < _maxBatchSize) {
      events.add(_eventQueue.removeFirst());
    }

    loggy.debug('Flushing ${events.length} events');

    final result = await apiService.sendEventsBatch(
      events: events,
      deviceId: deviceId,
      userId: userId,
      clientVersion: clientVersion,
    ).run();

    result.fold(
      (failure) {
        loggy.error('Failed to send events batch: $failure');
        // 失败时将事件放回队列（避免丢失）
        for (final event in events.reversed) {
          _eventQueue.addFirst(event);
        }
      },
      (response) {
        loggy.debug('Events batch sent successfully: saved=${response.saved}, failed=${response.failed}');
      },
    );
  }

  /// 快捷方法：追踪安装相关事件
  void trackInstallStarted({required int packageId, required String versionId}) {
    track(
      eventType: 'install_started',
      adId: packageId,
      extra: {'version_id': versionId},
    );
  }

  void trackInstallCompleted({
    required int packageId,
    required String versionId,
    required String status,
    String? message,
  }) {
    track(
      eventType: 'install_completed',
      adId: packageId,
      extra: {
        'version_id': versionId,
        'status': status,
        if (message != null) 'message': message,
      },
    );
  }

  void trackInstallFailed({
    required int packageId,
    required String versionId,
    required String error,
  }) {
    track(
      eventType: 'install_failed',
      adId: packageId,
      extra: {
        'version_id': versionId,
        'error': error,
      },
    );
  }

  /// 快捷方法：追踪下载相关事件
  void trackDownloadStarted({required int packageId, required String versionId}) {
    track(
      eventType: 'download_started',
      adId: packageId,
      extra: {'version_id': versionId},
    );
  }

  void trackDownloadCompleted({
    required int packageId,
    required String versionId,
    required int fileSize,
  }) {
    track(
      eventType: 'download_completed',
      adId: packageId,
      extra: {
        'version_id': versionId,
        'file_size': fileSize,
      },
    );
  }

  void trackDownloadFailed({
    required int packageId,
    required String versionId,
    required String error,
  }) {
    track(
      eventType: 'download_failed',
      adId: packageId,
      extra: {
        'version_id': versionId,
        'error': error,
      },
    );
  }

  /// 快捷方法：追踪应用启动/激活
  void trackAppLaunched() {
    track(eventType: 'app_launched');
  }

  void trackAppActivated() {
    track(eventType: 'app_activated');
  }
}
