import 'package:dio/dio.dart';
import 'package:hiddify/features/auth/model/auth_models.dart';
import 'package:hiddify/utils/custom_loggers.dart';

/// LrtsVPN API 服务
///
/// 支持两种登录方式:
/// 1. 直接登录 (账号密码)
/// 2. 设备授权登录 (浏览器跳转)
class AuthApiService with InfraLogger {
  static const baseUrl = 'https://lrtsvpn.com/api/v1';

  final Dio _dio;

  AuthApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            contentType: Headers.formUrlEncodedContentType,
          ),
        );

  /// 账号密码登录
  Future<AuthResult> login(String account, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/login',
      data: {'account': account, 'password': password},
    );
    final json = response.data!;
    if (json['ret'] != 1) {
      throw AuthException(json['msg'] as String? ?? '登录失败');
    }
    return AuthResult.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// 注册新账号
  Future<AuthResult> register(String account, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/register',
      data: {'account': account, 'password': password},
    );
    final json = response.data!;
    if (json['ret'] != 1) {
      throw AuthException(json['msg'] as String? ?? '注册失败');
    }
    return AuthResult.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// 发起设备授权 (浏览器登录流程第一步)
  Future<DeviceAuthInfo> startDeviceAuth() async {
    final response = await _dio.post<Map<String, dynamic>>('/auth/device');  // ignore: avoid_redundant_argument_values
    final json = response.data!;
    if (json['ret'] != 1) {
      throw const AuthException('获取设备码失败');
    }
    return DeviceAuthInfo.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// 轮询设备授权状态
  ///
  /// 返回 null 表示仍在等待中 (pending)
  /// 返回 AuthResult 表示授权成功
  /// 抛出 AuthException 表示设备码已过期
  Future<AuthResult?> checkDeviceAuth(String deviceCode) async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/check/$deviceCode');
    final json = response.data!;
    if (json['ret'] == 1) {
      final data = json['data'] as Map<String, dynamic>;
      if (data['status'] == 'authorized') {
        return AuthResult.fromJson(data);
      }
    }
    final data = json['data'] as Map<String, dynamic>?;
    if (data?['status'] == 'expired') {
      throw const AuthException('授权已过期，请重新登录');
    }
    return null; // pending
  }

  /// 构造 sing-box 订阅 URL
  ///
  /// 登录成功后，使用此 URL 作为 Profile 订阅地址
  String getSubscribeUrl(String token, {String type = 'singbox'}) {
    return '$baseUrl/nodes/$token/subscribe/$type';
  }

  /// 获取全部节点数据
  Future<Map<String, dynamic>> getNodes(String token) async {
    final response = await _dio.get<Map<String, dynamic>>('/nodes/$token');
    final json = response.data!;
    if (json['ret'] != 1) {
      throw AuthException(json['msg'] as String? ?? '获取节点失败');
    }
    return json['data'] as Map<String, dynamic>;
  }

  /// 获取订阅文本内容
  Future<String> getSubscribeContent(String token, {String type = 'singbox'}) async {
    final response = await _dio.get<String>(
      '/nodes/$token/subscribe/$type',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  /// 验证账号格式 (6-20位字母或数字)
  static String? validateAccount(String? value) {
    if (value == null || value.isEmpty) return '请输入账号';
    if (value.length < 6 || value.length > 20) return '账号长度必须为6-20位';
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) return '账号只能包含字母和数字';
    return null;
  }

  /// 验证密码格式 (6-20位字母或数字)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return '请输入密码';
    if (value.length < 6 || value.length > 20) return '密码长度必须为6-20位';
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) return '密码只能包含字母和数字';
    return null;
  }
}
