import '../../../core/network/api_exception.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
    this.phone,
    this.avatarUrl,
    this.birthYear,
    this.status,
    this.emailVerified = false,
    this.phoneVerified = false,
  });

  final int id;
  final String email;
  final String fullName;
  final List<String> roles;
  final String? phone;
  final String? avatarUrl;
  final int? birthYear;
  final String? status;
  final bool emailVerified;
  final bool phoneVerified;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: (json['id'] as num).toInt(),
    email: json['email']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? '',
    roles: (json['roles'] as List? ?? const [])
        .map((value) => value.toString())
        .toList(growable: false),
    phone: json['phone']?.toString(),
    avatarUrl: json['avatarUrl']?.toString(),
    birthYear: (json['birthYear'] as num?)?.toInt(),
    status: json['status']?.toString(),
    emailVerified: json['emailVerified'] == true,
    phoneVerified: json['phoneVerified'] == true,
  );
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInMs,
    required this.user,
    required this.roles,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInMs;
  final AuthUser user;
  final List<String> roles;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'].toString(),
    refreshToken: json['refreshToken'].toString(),
    tokenType: json['tokenType'].toString(),
    expiresInMs: (json['expiresInMs'] as num).toInt(),
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    roles: (json['roles'] as List? ?? const [])
        .map((value) => value.toString())
        .toList(growable: false),
  );
}

class RegistrationProfile {
  const RegistrationProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
    this.username,
    this.phone,
    this.avatarUrl,
    this.birthYear,
    this.preferredCinemaId,
    this.status,
    this.emailVerified = false,
    this.phoneVerified = false,
  });

  final int? id;
  final String email;
  final String fullName;
  final List<String> roles;
  final String? username;
  final String? phone;
  final String? avatarUrl;
  final int? birthYear;
  final int? preferredCinemaId;
  final String? status;
  final bool emailVerified;
  final bool phoneVerified;

  factory RegistrationProfile.fromJson(Map<String, dynamic> json) {
    try {
      return RegistrationProfile(
        id: json['id'] as int?,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        roles: (json['roles'] as List? ?? const []).cast<String>().toList(
          growable: false,
        ),
        username: json['username'] as String?,
        phone: json['phone'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        birthYear: json['birthYear'] as int?,
        preferredCinemaId: json['preferredCinemaId'] as int?,
        status: json['status'] as String?,
        emailVerified: (json['emailVerified'] as bool?) ?? false,
        phoneVerified: (json['phoneVerified'] as bool?) ?? false,
      );
    } on TypeError {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid registration profile',
      );
    }
  }
}

class RegistrationResult {
  const RegistrationResult({
    required this.user,
    required this.emailVerificationRequired,
    required this.emailVerificationExpiresInSeconds,
  });

  final RegistrationProfile user;
  final bool emailVerificationRequired;
  final int emailVerificationExpiresInSeconds;

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final verificationRequired = json['emailVerificationRequired'];
    final expiry = json['emailVerificationExpiresInSeconds'];
    if (user is! Map<String, dynamic> ||
        verificationRequired is! bool ||
        expiry is! int) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid registration response',
      );
    }
    return RegistrationResult(
      user: RegistrationProfile.fromJson(user),
      emailVerificationRequired: verificationRequired,
      emailVerificationExpiresInSeconds: expiry,
    );
  }
}
