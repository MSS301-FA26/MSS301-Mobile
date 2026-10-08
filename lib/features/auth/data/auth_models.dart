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

class RegistrationResult {
  const RegistrationResult({
    required this.user,
    required this.emailVerificationRequired,
    required this.emailVerificationExpiresInSeconds,
  });

  final AuthUser user;
  final bool emailVerificationRequired;
  final int emailVerificationExpiresInSeconds;

  factory RegistrationResult.fromJson(Map<String, dynamic> json) =>
      RegistrationResult(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        emailVerificationRequired: json['emailVerificationRequired'] == true,
        emailVerificationExpiresInSeconds:
            (json['emailVerificationExpiresInSeconds'] as num).toInt(),
      );
}
