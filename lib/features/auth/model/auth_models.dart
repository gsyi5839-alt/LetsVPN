/// LrtsVPN API 认证相关数据模型
///
/// Base URL: https://lrtsvpn.com/api/v1
library;

class AuthUser {
  final int id;
  final String account;
  final String uuid;

  const AuthUser({
    required this.id,
    required this.account,
    required this.uuid,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    account: json['account'] as String,
    uuid: json['uuid'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'account': account,
    'uuid': uuid,
  };
}

class AuthResult {
  final String token;
  final AuthUser user;

  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    token: json['token'] as String,
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class DeviceAuthInfo {
  final String deviceCode;
  final String userCode;
  final String loginUrl;
  final int expiresIn;
  final int interval;

  const DeviceAuthInfo({
    required this.deviceCode,
    required this.userCode,
    required this.loginUrl,
    required this.expiresIn,
    required this.interval,
  });

  factory DeviceAuthInfo.fromJson(Map<String, dynamic> json) => DeviceAuthInfo(
    deviceCode: json['device_code'] as String,
    userCode: json['user_code'] as String,
    loginUrl: json['login_url'] as String,
    expiresIn: json['expires_in'] as int,
    interval: json['interval'] as int,
  );
}

/// 认证状态
class AuthState {
  final bool isLoggedIn;
  final String? token;
  final String? account;
  final String? uuid;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.token,
    this.account,
    this.uuid,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? token,
    String? account,
    String? uuid,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        token: token ?? this.token,
        account: account ?? this.account,
        uuid: uuid ?? this.uuid,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

/// API 异常
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
