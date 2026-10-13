import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../auth/application/auth_session.dart';
import '../data/chat_repository.dart';

class PopBotChatPage extends ConsumerStatefulWidget {
  const PopBotChatPage({super.key});
  @override
  ConsumerState<PopBotChatPage> createState() => _PopBotChatPageState();
}

class _PopBotChatPageState extends ConsumerState<PopBotChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({bool user, String text})>[];
  String? _conversation, _error, _retryText;
  bool _busy = false;
  int _generation = 0;
  CancelToken? _cancel;
  @override
  void dispose() {
    _cancel?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _reset() {
    _cancel?.cancel();
    _generation++;
    setState(() {
      _messages.clear();
      _conversation = null;
      _error = null;
      _retryText = null;
      _busy = false;
      _input.clear();
    });
  }

  Future<void> _send({String? retry}) async {
    if (_busy) return;
    final text = (retry ?? _input.text).trim();
    if (text.isEmpty || text.length > 1000) return;
    final generation = _generation;
    final cancel = CancelToken();
    _cancel = cancel;
    setState(() {
      _busy = true;
      _error = null;
      _retryText = null;
      if (retry == null) {
        _messages.add((user: true, text: text));
        _input.clear();
      }
    });
    try {
      final reply = await ref
          .read(chatRepositoryProvider)
          .send(
            text,
            conversationId: _conversation,
            userId: ref.read(authSessionProvider).session?.user.id,
            cancelToken: cancel,
          );
      if (!mounted || generation != _generation) return;
      setState(() {
        _conversation = reply.conversationId;
        _messages.add((user: false, text: reply.reply));
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _retryText = text;
        _error = 'PopBot chưa thể trả lời lúc này. Vui lòng thử lại.';
      });
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(
      authSessionProvider.select((auth) => auth.session?.user.id),
      (previous, next) {
        if (previous != next) _reset();
      },
    );
    return AppShell(
      currentIndex: 0,
      showBottomNavigation: false,
      body: Column(
        children: [
          ListTile(
            leading: IconButton(
              tooltip: 'Về Trang chủ',
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('PopBot AI', style: AppTextStyles.sectionTitle),
            trailing: IconButton(
              tooltip: 'Cuộc trò chuyện mới',
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Bạn muốn xem phim gì? Hãy hỏi PopBot về phim, rạp hoặc suất chiếu.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.user
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                          ),
                          decoration: BoxDecoration(
                            color: message.user
                                ? AppColors.goldSurface
                                : AppColors.surfaceRaised,
                            borderRadius: AppRadii.card,
                          ),
                          child: SelectableText(
                            message.text,
                            style: AppTextStyles.body,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('PopBot đang trả lời…', style: AppTextStyles.caption),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text(_error!, style: AppTextStyles.caption)),
                  TextButton(
                    onPressed: _busy ? null : () => _send(retry: _retryText),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('popbot-input'),
                    controller: _input,
                    enabled: !_busy,
                    maxLength: 1000,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Nhắn cho PopBot…',
                      counterText: '',
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  key: const ValueKey('popbot-send'),
                  tooltip: 'Gửi tin nhắn',
                  onPressed: _busy ? null : () => _send(),
                  icon: const Icon(Icons.send_rounded, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
