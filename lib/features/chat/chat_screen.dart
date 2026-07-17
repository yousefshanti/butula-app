import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Mark chat read on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firestoreServiceProvider)?.markChatRead();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load older messages when scrolled near the top.
    if (_scroll.hasClients && _scroll.position.pixels <= 60) {
      final loaded = ref.read(chatMessagesProvider).valueOrNull?.length ?? 0;
      final limit = ref.read(chatLimitProvider);
      if (loaded >= limit) {
        ref.read(chatLimitProvider.notifier).state = limit + 50;
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final user = ref.read(appUserProvider).valueOrNull;
    final svc = ref.read(firestoreServiceProvider);
    if (user == null || svc == null) return;
    setState(() => _sending = true);
    _controller.clear();
    await svc.sendChatMessage(text, user.name);
    await svc.markChatRead();
    if (mounted) {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final uid = ref.watch(currentUidProvider);
    final messagesAsync = ref.watch(chatMessagesProvider);

    // Auto-scroll to bottom and mark read when new messages arrive.
    ref.listen(chatMessagesProvider, (prev, next) {
      final list = next.valueOrNull ?? const [];
      if (list.length != _lastCount) {
        _lastCount = list.length;
        ref.read(firestoreServiceProvider)?.markChatRead();
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(s.chat)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${s.error}\n$e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return EmptyState(emoji: '💬', title: s.chatEmpty);
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMe = m.senderUid == uid;
                    final showName = !isMe &&
                        (i == 0 || messages[i - 1].senderUid != m.senderUid);
                    return _Bubble(message: m, isMe: isMe, showName: showName);
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _controller,
            sending: _sending,
            hint: s.chatHint,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMe,
    required this.showName,
  });
  final ChatMessage message;
  final bool isMe;
  final bool showName;

  String _time(DateTime? t) {
    if (t == null) return '';
    final local = t.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isMe
        ? BrandColors.green
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isMe ? Colors.white : theme.colorScheme.onSurface;
    return Align(
      alignment:
          isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showName)
              Text(
                message.senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: BrandColors.gold, fontWeight: FontWeight.bold),
              ),
            Text(message.text, style: TextStyle(color: fg, fontSize: 15)),
            const SizedBox(height: 2),
            Text(_time(message.sentAt),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: fg.withValues(alpha: 0.6), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.hint,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hint,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: BrandColors.green,
              child: IconButton(
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: sending ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
