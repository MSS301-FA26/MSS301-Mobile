import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/account/application/profile_controller.dart';

class _RealNetwork extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'avatar verifier downloads and decodes a real image without auth',
    (tester) async {
      await tester.runAsync(
        () => HttpOverrides.runZoned(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          String? authorization;
          server.listen((request) async {
            authorization = request.headers.value(
              HttpHeaders.authorizationHeader,
            );
            request.response.headers.contentType = ContentType('image', 'png');
            request.response.add(
              base64Decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
              ),
            );
            await request.response.close();
          });
          try {
            await AvatarVerifier().verify(
              'http://127.0.0.1:${server.port}/image',
            );
            expect(authorization, isNull);
          } finally {
            await server.close(force: true);
          }
        }, createHttpClient: _RealNetwork().createHttpClient),
      );
    },
  );

  for (final scenario in ['html', 'missing', 'oversize']) {
    testWidgets('avatar verifier rejects $scenario response', (tester) async {
      await tester.runAsync(
        () => HttpOverrides.runZoned(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          server.listen((request) async {
            if (scenario == 'missing') {
              request.response.statusCode = 404;
            } else if (scenario == 'oversize') {
              request.response.add(List<int>.filled(5 * 1024 * 1024 + 1, 0));
            } else {
              request.response.write('<html>This is not an image</html>');
            }
            try {
              await request.response.close();
            } on SocketException {
              // Cancellation can close the socket while the server sends bytes.
            }
          });
          try {
            await expectLater(
              AvatarVerifier().verify('http://127.0.0.1:${server.port}/image'),
              throwsA(isA<Object>()),
            );
          } finally {
            await server.close(force: true);
          }
        }, createHttpClient: _RealNetwork().createHttpClient),
      );
    });
  }

  test(
    'avatar verifier rejects unsupported URLs and cancelled requests',
    () async {
      for (final url in [
        'file:///tmp/image.png',
        'ftp://example.test/image',
        'bad',
      ]) {
        await expectLater(AvatarVerifier().verify(url), throwsA(isA<Object>()));
      }
      final cancel = CancelToken()..cancel();
      await expectLater(
        AvatarVerifier().verify(
          'http://127.0.0.1:1/image',
          cancelToken: cancel,
        ),
        throwsA(isA<DioException>()),
      );
    },
  );
}
