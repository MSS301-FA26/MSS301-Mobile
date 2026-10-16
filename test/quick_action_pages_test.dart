import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/food/data/repositories/standalone_food_repository.dart';
import 'package:mss301_mobile/features/popbot/data/chat_repository.dart';

import 'quick_action_api_test.dart' as fixtures;
import 'support/pump_test_app.dart';

void main() {
  testWidgets(
    'failed chat retries once without duplicating prompt or inventing reply',
    (tester) async {
      var calls = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls++;
            if (calls == 1) {
              handler.reject(DioException(requestOptions: request));
            } else {
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: fixtures.envelope({
                    'conversationId': 'qa',
                    'reply': 'API reply',
                  }),
                ),
              );
            }
          },
        ),
      );
      await pumpTestApp(
        tester,
        initialLocation: AppRoutes.chat,
        providerOverrides: [
          chatRepositoryProvider.overrideWithValue(ChatRepository(dio)),
        ],
      );
      await tester.enterText(
        find.byKey(const ValueKey('popbot-input')),
        'QA prompt',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(find.text('QA prompt'), findsOneWidget);
      expect(find.text('API reply'), findsNothing);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('QA prompt'), findsOneWidget);
      expect(find.text('API reply'), findsOneWidget);
    },
  );

  testWidgets('reset discards late chat response', (tester) async {
    final pending = Completer<ChatReply>();
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.chat,
      providerOverrides: [
        chatRepositoryProvider.overrideWithValue(_PendingChat(pending)),
      ],
    );
    await tester.enterText(
      find.byKey(const ValueKey('popbot-input')),
      'Old prompt',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pump();
    await tester.tap(find.byTooltip('Cuộc trò chuyện mới'));
    pending.complete(const ChatReply('old', 'Old response'));
    await tester.pumpAndSettle();
    expect(find.text('Old response'), findsNothing);
    expect(find.text('Old prompt'), findsNothing);
  });

  for (final status in ['PENDING_PAYMENT', 'PAID', 'EXPIRED']) {
    testWidgets(
      'food receipt $status exposes QR and payment only for valid state',
      (tester) async {
        final data = fixtures.order(status: status);
        data['qrCode'] = 'server-issued-qr';
        data['expiresAt'] = '2099-01-01T10:00:00Z';
        await pumpTestApp(
          tester,
          initialLocation: AppRoutes.foodOrderDetail(9),
          providerOverrides: [
            standaloneFoodRepositoryProvider.overrideWithValue(
              StandaloneFoodRepository(
                fixtures.responding((_) => fixtures.envelope(data)),
              ),
            ),
          ],
        );
        expect(
          find.byType(QrImageView),
          status == 'PAID' ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const ValueKey('food-pay')),
          status == 'PENDING_PAYMENT' ? findsOneWidget : findsNothing,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

class _PendingChat extends ChatRepository {
  _PendingChat(this.pending) : super(Dio());
  final Completer<ChatReply> pending;
  @override
  Future<ChatReply> send(
    String message, {
    String? conversationId,
    int? userId,
    CancelToken? cancelToken,
  }) => pending.future;
}
