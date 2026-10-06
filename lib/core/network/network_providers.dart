import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';
import 'dio_client.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromDartDefines(),
);

final apiConfigProvider = Provider<ApiConfig>(
  (ref) => ApiConfig(appConfig: ref.watch(appConfigProvider)),
);

final dioProvider = Provider<Dio>(
  (ref) => createDioClient(ref.watch(apiConfigProvider)),
);
