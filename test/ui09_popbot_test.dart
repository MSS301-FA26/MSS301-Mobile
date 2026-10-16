import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/popbot/data/chat_repository.dart';
import 'package:mss301_mobile/features/popbot/presentation/chat_page.dart';

import 'support/fake_auth_session.dart';

class PendingChat extends ChatRepository {
  PendingChat() : super(Dio());
  final requests =
      <({String text, String? conversation, CancelToken? token})>[];
  final pending = <Completer<ChatReply>>[];
  @override
  Future<ChatReply> send(
    String message, {
    String? conversationId,
    int? userId,
    CancelToken? cancelToken,
  }) {
    requests.add((
      text: message,
      conversation: conversationId,
      token: cancelToken,
    ));
    final request = Completer<ChatReply>();
    pending.add(request);
    return request.future;
  }
}

Future<ProviderContainer> open(
  WidgetTester tester,
  PendingChat repo, {
  double width = 390,
  double scale = 1,
  double keyboard = 0,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 780));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
        authSessionProvider.overrideWith(
          () => FakeAuthSessionController(authenticatedCustomerState()),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 780),
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: const PopBotChatPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(PopBotChatPage)));
}

Future<void> send(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('popbot-input')), text);
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('popbot-send')));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
      'suggestions, long reply and keyboard fit $width at 1.6 scale',
      (tester) async {
        final repo = PendingChat();
        await open(tester, repo, width: width, scale: 1.6, keyboard: 280);
        expect(tester.takeException(), isNull);
        final input = find.byKey(const ValueKey('popbot-input'));
        expect(tester.getBottomLeft(input).dy, lessThanOrEqualTo(500));
        await send(tester, List.filled(20, 'Câu hỏi dài ').join());
        expect(find.text('PopBot đang trả lời…'), findsOneWidget);
        repo.pending.first.complete(
          ChatReply('thread', List.filled(90, 'Nội dung trả lời dài. ').join()),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getBottomLeft(input).dy, lessThanOrEqualTo(500));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'suggestion drafts only; empty, over limit and busy cannot submit; conversation preserved',
    (tester) async {
      final repo = PendingChat();
      await open(tester, repo);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('popbot-send')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Gợi ý phim cho buổi hẹn hò'));
      await tester.pumpAndSettle();
      expect(repo.requests, isEmpty);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('popbot-input')))
            .controller!
            .text,
        'Gợi ý phim cho buổi hẹn hò',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('popbot-send')));
      await tester.pumpAndSettle();
      expect(repo.requests, hasLength(1));
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('popbot-send')))
            .onPressed,
        isNull,
      );
      repo.pending.first.complete(
        const ChatReply('thread-1', 'Phản hồi thật từ repository'),
      );
      await tester.pumpAndSettle();
      await send(tester, 'Còn phim nào khác?');
      expect(repo.requests.last.conversation, 'thread-1');
      repo.pending.last.complete(const ChatReply('thread-1', 'Phản hồi tiếp'));
      await tester.pumpAndSettle();
      // Programmatic over-limit input still cannot bypass the request guard.
      tester
              .widget<TextField>(find.byKey(const ValueKey('popbot-input')))
              .controller!
              .text =
          'a' * 1001;
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('popbot-send')))
            .onPressed,
        isNull,
      );
      expect(repo.requests, hasLength(2));
    },
  );

  testWidgets(
    'failed prompt can be edited and resent without stale failed bubble',
    (tester) async {
      final repo = PendingChat();
      await open(tester, repo);
      await send(tester, 'Câu hỏi cũ');
      repo.pending.first.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sửa câu hỏi'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('popbot-input')))
            .controller!
            .text,
        'Câu hỏi cũ',
      );
      await send(tester, 'Câu hỏi đã sửa');
      expect(repo.requests.last.text, 'Câu hỏi đã sửa');
      expect(find.text('Câu hỏi cũ'), findsNothing);
      repo.pending.last.complete(const ChatReply('new', 'Đã trả lời'));
      await tester.pumpAndSettle();
      expect(find.text('Đã trả lời'), findsOneWidget);
    },
  );

  testWidgets(
    'account change cancels pending and discards conversation and late replies',
    (tester) async {
      final repo = PendingChat();
      final container = await open(tester, repo);
      await send(tester, 'Private prompt');
      await container.read(authSessionProvider.notifier).logout();
      await tester.pumpAndSettle();
      expect(repo.requests.first.token!.isCancelled, isTrue);
      repo.pending.first.complete(const ChatReply('old', 'Private reply'));
      await tester.pumpAndSettle();
      expect(find.text('Private prompt'), findsNothing);
      expect(find.text('Private reply'), findsNothing);
      await send(tester, 'New guest prompt');
      expect(repo.requests.last.conversation, isNull);
      repo.pending.last.complete(const ChatReply('guest', 'Guest reply'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'reply does not pull reader away from old text; new-message button reveals reply',
    (tester) async {
      final repo = PendingChat();
      await open(tester, repo);
      await send(tester, 'First');
      repo.pending.first.complete(
        ChatReply('thread', List.filled(120, 'Long reply line.\n').join()),
      );
      await tester.pumpAndSettle();
      await send(tester, 'Second');
      expect(repo.requests, hasLength(2));
      final list = find.byKey(const ValueKey('popbot-conversation'));
      final controller = tester.widget<ListView>(list).controller!;
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      repo.pending.last.complete(const ChatReply('thread', 'Newest reply'));
      await tester.pumpAndSettle();
      expect(controller.offset, 0);
      expect(find.text('Tin nhắn mới'), findsOneWidget);
      await tester.tap(find.text('Tin nhắn mới'));
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(2));
      expect(find.text('Newest reply'), findsOneWidget);
      expect(find.text('Newest reply').hitTestable(), findsOneWidget);
    },
  );
}
