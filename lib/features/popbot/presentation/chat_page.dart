import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/popbot_avatar.dart';
import '../../auth/application/auth_session.dart';
import '../data/chat_repository.dart';
import 'widgets/chat_cinema_background.dart';

class _ChatTurn {
  _ChatTurn(this.prompt);
  final String prompt;
  String? reply, error;
}

class PopBotChatPage extends ConsumerStatefulWidget {
  const PopBotChatPage({super.key});
  @override
  ConsumerState<PopBotChatPage> createState() => _PopBotChatPageState();
}

class _PopBotChatPageState extends ConsumerState<PopBotChatPage> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _turns = <_ChatTurn>[];
  String? _conversation;
  bool _busy = false, _unread = false;
  int _generation = 0;
  int _scrollRequest = 0;
  CancelToken? _cancel;

  bool get _nearBottom =>
      !_scroll.hasClients || _scroll.position.extentAfter < 100;
  bool get _failed => _turns.isNotEmpty && _turns.last.error != null;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_unread && _nearBottom) setState(() => _unread = false);
  }

  void _showLatest() {
    final generation = _generation;
    final request = ++_scrollRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Lazy list extents can grow after a long reply is first laid out.
      for (var attempt = 0; attempt < 5; attempt++) {
        if (!mounted ||
            generation != _generation ||
            request != _scrollRequest ||
            !_scroll.hasClients) {
          return;
        }
        await _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
        if (!mounted || !_scroll.hasClients) return;
        if ((_scroll.offset - _scroll.position.maxScrollExtent).abs() < 1) {
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _reset() {
    _cancel?.cancel();
    _generation++;
    setState(() {
      _turns.clear();
      _conversation = null;
      _busy = false;
      _unread = false;
      _input.clear();
    });
  }

  void _editFailed() {
    if (_busy || !_failed) return;
    setState(() {
      _input.text = _turns.removeLast().prompt;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    });
    _focus.requestFocus();
  }

  Future<void> _send({bool retry = false}) async {
    if (_busy || (!retry && _failed)) return;
    if (retry && !_failed) return;
    final text = (retry ? _turns.last.prompt : _input.text).trim();
    if (text.isEmpty || text.length > 1000) return;
    final generation = _generation;
    final cancel = CancelToken();
    _cancel = cancel;
    final turn = retry ? _turns.last : _ChatTurn(text);
    setState(() {
      _busy = true;
      _unread = false;
      turn.error = null;
      if (!retry) {
        _turns.add(turn);
        _input.clear();
      }
    });
    _showLatest();
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
      final follow = _nearBottom;
      setState(() {
        _conversation = reply.conversationId;
        turn.reply = reply.reply;
        _unread = !follow;
      });
      if (follow) _showLatest();
    } catch (_) {
      if (!mounted || generation != _generation) return;
      final follow = _nearBottom;
      setState(() {
        turn.error = 'PopBot chưa thể trả lời lúc này. Bạn có thể thử lại hoặc sửa câu hỏi.';
        _unread = !follow;
      });
      if (follow) _showLatest();
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Về Trang chủ',
          onPressed: () => context.go(AppRoutes.home),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Row(
          children: [
            PopBotAvatar(size: 36),
            SizedBox(width: 10),
            Expanded(child: Text('PopBot AI', style: AppTextStyles.cardTitle)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: _reset,
            icon: const Icon(
              Icons.add_comment_outlined,
              color: AppColors.lavender,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ChatCinemaBackground(
          child: Column(
            children: [
              Expanded(
                child: _turns.isEmpty
                    ? _welcome()
                    : NotificationListener<UserScrollNotification>(
                        onNotification: (notification) {
                          if (notification.direction != ScrollDirection.idle) {
                            _scrollRequest++;
                          }
                          return false;
                        },
                        child: ListView.builder(
                          key: const ValueKey('popbot-conversation'),
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: _turns.length,
                          itemBuilder: (context, index) {
                            final turn = _turns[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _bubble(turn.prompt, user: true),
                                if (turn.reply != null)
                                  _bubble(turn.reply!, user: false),
                                if (_busy && index == _turns.length - 1)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 20),
                                    child: Row(
                                      children: [
                                        PopBotAvatar(size: 28),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Semantics(
                                            liveRegion: true,
                                            child: Text(
                                              'PopBot đang trả lời…',
                                              style: TextStyle(
                                                color: AppColors.lavender,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (turn.error != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceRaised,
                                      borderRadius: AppRadii.card,
                                      border: Border.all(
                                        color: AppColors.lavender.withValues(
                                          alpha: .4,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Semantics(
                                          liveRegion: true,
                                          child: Text(
                                            turn.error!,
                                            style: AppTextStyles.body,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _send(retry: true),
                                              icon: const Icon(Icons.refresh),
                                              label: const Text('Thử lại'),
                                            ),
                                            TextButton.icon(
                                              onPressed: _editFailed,
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              label: const Text('Sửa câu hỏi'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
              if (_unread)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _unread = false);
                    _showLatest();
                  },
                  icon: const Icon(Icons.arrow_downward_rounded),
                  label: const Text('Tin nhắn mới'),
                ),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcome() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 24),
      const Center(child: PopBotAvatar(size: 64)),
      const SizedBox(height: 20),
      const Text(
        'Hôm nay bạn muốn xem gì?',
        textAlign: TextAlign.center,
        style: AppTextStyles.sectionTitle,
      ),
      const SizedBox(height: 10),
      const Text(
        'Cùng PopBot tìm phim hợp gu, khám phá rạp và suất chiếu.',
        textAlign: TextAlign.center,
        style: AppTextStyles.body,
      ),
      const SizedBox(height: 28),
      const Text('Chạm để soạn câu hỏi', style: AppTextStyles.caption),
      const SizedBox(height: 8),
      for (final prompt in const [
        'Gợi ý phim cho buổi hẹn hò',
        'Có phim nào phù hợp cho cả gia đình?',
        'Làm sao để đặt vé xem phim?',
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.lavender,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(16),
              side: BorderSide(color: AppColors.purple.withValues(alpha: .5)),
            ),
            onPressed: () {
              _input.text = prompt;
              _focus.requestFocus();
            },
            child: Text(prompt),
          ),
        ),
    ],
  );

  Widget _bubble(String text, {required bool user}) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!user) ...[const PopBotAvatar(size: 28), const SizedBox(width: 8)],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * .8,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: user
                  ? AppColors.purple.withValues(alpha: .28)
                  : AppColors.surfaceRaised,
              borderRadius: AppRadii.card,
              border: Border.all(
                color: user
                    ? AppColors.purple.withValues(alpha: .5)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user ? 'Bạn' : 'PopBot',
                  style: const TextStyle(
                    color: AppColors.lavender,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(text, style: AppTextStyles.body),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _composer() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    decoration: const BoxDecoration(color: AppColors.surface),
    child: ValueListenableBuilder<TextEditingValue>(
      valueListenable: _input,
      builder: (context, value, _) => Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('popbot-input'),
                  controller: _input,
                  focusNode: _focus,
                  enabled: !_busy && !_failed,
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Nhắn cho PopBot…',
                    counterText: '',
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  onTap: () {
                    if (_nearBottom) _showLatest();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey('popbot-send'),
                tooltip: 'Gửi tin nhắn',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                onPressed:
                    _busy ||
                        _failed ||
                        value.text.trim().isEmpty ||
                        value.text.trim().length > 1000
                    ? null
                    : () => _send(),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kiểm tra lại thông tin trước khi đặt vé.',
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${value.text.characters.length}/1000',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
