import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mss301_mobile/core/auth/token_storage.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:mss301_mobile/features/auth/data/remote_auth_repository.dart';

const googleCredential = 'test-google-id-token';

Map<String, Object?> googleSessionEnvelope() => {
  'success': true,
  'data': {
    'accessToken': 'application-access-token',
    'refreshToken': 'application-refresh-token',
    'tokenType': 'Bearer',
    'expiresInMs': 3600000,
    'user': {
      'id': 5101,
      'email': 'customer@example.test',
      'fullName': 'Google Customer',
      'emailVerified': true,
      'roles': ['CUSTOMER'],
    },
    'roles': ['CUSTOMER'],
  },
};

RemoteAuthRepository googleTestRepository(
  GoogleAuthHttpAdapter adapter,
  GoogleAuthTokenStorage storage,
) => RemoteAuthRepository(
  AuthRemoteDataSource(Dio()..httpClientAdapter = adapter),
  storage,
);

class GoogleAuthHttpAdapter implements HttpClientAdapter {
  GoogleAuthHttpAdapter() : responseBody = googleSessionEnvelope();

  Object? responseBody;
  int statusCode = 200;
  ApiException? error;
  Completer<void>? responseGate;
  final firstRequest = Completer<void>();
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (!firstRequest.isCompleted) firstRequest.complete();
    if (options.path != '/api/v1/auth/logout') {
      await responseGate?.future;
    }
    final failure = error;
    if (failure != null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        error: failure,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class GoogleAuthTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveAccessToken(String token) async {
    saveCalls++;
    accessToken = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    saveCalls++;
    refreshToken = token;
  }

  @override
  Future<void> deleteAccessToken() async {
    accessToken = null;
  }

  @override
  Future<void> deleteRefreshToken() async {
    refreshToken = null;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    accessToken = null;
    refreshToken = null;
  }
}
