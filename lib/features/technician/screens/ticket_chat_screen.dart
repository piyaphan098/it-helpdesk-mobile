import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:it_support_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_message.dart';

class TicketChatScreen extends ConsumerStatefulWidget {
  const TicketChatScreen({
    super.key,
    required this.ticketId,
    required this.ticketTitle,
  });

  final String ticketId;
  final String ticketTitle;

  @override
  ConsumerState<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends ConsumerState<TicketChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late Stream<List<ChatMessage>> _stream;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(chatRepositoryProvider);
    _stream = repo.messagesStream(widget.ticketId);
    // ดึงข้อมูล initial พร้อม profile names
    ref.read(chatMessagesProvider(widget.ticketId));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String currentUserId) async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            ticketId: widget.ticketId,
            authorId: currentUserId,
            content: text,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งข้อความไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final initialMessagesAsync =
        ref.watch(chatMessagesProvider(widget.ticketId));

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('แชท', style: TextStyle(fontSize: 16)),
                Text(
                  widget.ticketTitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // ── Message List ──
              Expanded(
                child: initialMessagesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('โหลดข้อความไม่ได้: $e')),
                  data: (_) => StreamBuilder<List<ChatMessage>>(
                    stream: _stream,
                    builder: (context, snapshot) {
                      // ใช้ initial messages ที่มี profile names เป็น fallback
                      final streamMessages = snapshot.data;
                      final initialMessages =
                          initialMessagesAsync.valueOrNull ?? [];

                      // merge: stream messages แต่ใช้ชื่อจาก initial
                      final nameMap = {
                        for (final m in initialMessages)
                          m.authorId: m.authorName
                      };

                      final messages = (streamMessages ?? initialMessages)
                          .map((m) => ChatMessage(
                                id: m.id,
                                ticketId: m.ticketId,
                                authorId: m.authorId,
                                authorName: nameMap[m.authorId] ?? m.authorName,
                                content: m.content,
                                createdAt: m.createdAt,
                                imageUrls: m.imageUrls,
                              ))
                          .toList();

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 56,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text('ยังไม่มีข้อความ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                              const SizedBox(height: 4),
                              Text('เริ่มแชทกับช่างซ่อมได้เลย',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                            ],
                          ),
                        );
                      }

                      _scrollToBottom();

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[i];
                          final isMe = msg.authorId == profile.id;
                          final showDate = i == 0 ||
                              !_isSameDay(
                                  messages[i - 1].createdAt, msg.createdAt);
                          return Column(
                            children: [
                              if (showDate) _DateDivider(msg.createdAt),
                              _MessageBubble(message: msg, isMe: isMe),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              // ── Input ──
              _ChatInput(
                controller: _textController,
                isSending: _isSending,
                onSend: () => _sendMessage(profile.id),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Date Divider ─────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider(this.date);
  final DateTime date;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'วันนี้';
    if (d == today.subtract(const Duration(days: 1))) return 'เมื่อวาน';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(_label(),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});
  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                message.authorName.isNotEmpty
                    ? message.authorName[0].toUpperCase()
                    : '?',
                style:
                    TextStyle(fontSize: 12, color: theme.colorScheme.secondary),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(message.authorName,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(time,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Chat Input ───────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
              top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความ...',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSending
                  ? const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : FloatingActionButton.small(
                      heroTag: 'send_btn',
                      onPressed: onSend,
                      elevation: 0,
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


