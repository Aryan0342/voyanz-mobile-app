import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/chat/providers/chat_messages_notifier.dart';

String _resolveMediaUrl(String raw) {
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final normalized = raw.startsWith('/') ? raw : '/$raw';
  return '${EnvConfig.current.baseUrl}$normalized';
}

class ChatMessagesScreen extends ConsumerStatefulWidget {
  final String chgrId;

  const ChatMessagesScreen({super.key, required this.chgrId});

  @override
  ConsumerState<ChatMessagesScreen> createState() => _ChatMessagesScreenState();
}

class _ChatMessagesScreenState extends ConsumerState<ChatMessagesScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _readMessageIds = <String>{};
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(chatMessagesNotifierProvider(widget.chgrId).notifier)
          .sendMessage(text);
      _msgCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(translationsProvider).sendMessageFailed(e.toString()),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markMessagesRead(List<ChatMessage> messages) async {
    final currentCoId = ref.read(authStateProvider).valueOrNull?.coId;
    final pendingIds = <int>[];

    for (final message in messages) {
      if (message.chmeId.startsWith('local-')) continue;
      if (_readMessageIds.contains(message.chmeId)) continue;
      if (currentCoId != null && message.senderCoId == currentCoId) continue;

      final id = message.numericId;
      if (id == null) continue;

      pendingIds.add(id);
      _readMessageIds.add(message.chmeId);
    }

    if (pendingIds.isEmpty) return;

    final ws = ref.read(webSocketServiceProvider);
    for (var i = 0; i < pendingIds.length; i += 500) {
      final end = i + 500 < pendingIds.length ? i + 500 : pendingIds.length;
      await ws.sendWithToken('chat_messagesreaded', pendingIds.sublist(i, end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      chatMessagesNotifierProvider(widget.chgrId),
    );
    final t = ref.watch(translationsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: VoyanzAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.accent,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.conversation,
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  t.activeNow,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          VoyanzAppBarIconButton(icon: Icons.more_vert, onPressed: () {}),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.mediumPurple,
                  ),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.failedLoadMessages,
                        style: GoogleFonts.montserrat(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.accent.scale(0.3),
                            ),
                            child: const Icon(
                              Icons.chat,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            t.noMessagesYet,
                            style: GoogleFonts.jost(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.startConversation,
                            style: GoogleFonts.montserrat(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    unawaited(_markMessagesRead(messages));
                  });

                  return ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[messages.length - 1 - i];
                      final currentUser = ref
                          .watch(authStateProvider)
                          .valueOrNull;
                      final isMe =
                          (msg.senderCoId != null &&
                          msg.senderCoId == currentUser?.coId);
                      return _RevealIn(
                        delayMs: i * 18,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _MessageBubble(message: msg, isMe: isMe),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // ── Message input ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withValues(alpha: 0.98),
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: TextField(
                          controller: _msgCtrl,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          style: GoogleFonts.manrope(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: t.typeMessage,
                            hintStyle: GoogleFonts.manrope(
                              color: AppColors.textMuted,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _sending
                            ? AppColors.textMuted
                            : AppColors.mediumPurple,
                        boxShadow: _sending
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.mediumPurple.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: IconButton(
                        onPressed: _sending ? null : _send,
                        icon: Icon(
                          _sending ? Icons.hourglass_empty : Icons.send_rounded,
                          size: 20,
                        ),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasImage =
        (message.imageUrl != null && message.imageUrl!.trim().isNotEmpty) ||
        (message.isImage && message.chmeId.trim().isNotEmpty);
    String? imageUrl;
    if (hasImage) {
      final raw = message.imageUrl?.trim();
      if (raw != null && raw.isNotEmpty) {
        imageUrl = _resolveMediaUrl(raw);
      } else {
        final endpoint = ref
            .read(chatRepositoryProvider)
            .getImageUrl(message.chmeId);
        imageUrl = _resolveMediaUrl(endpoint);
      }
    }

    final isPending = message.chmeId.startsWith('local-');

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.accent,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    message.senderName ?? t.unknown,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mediumPurple,
                    ),
                  ),
                ),

              // Optimistic marker handled above
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isMe ? AppGradients.accent : null,
                  color: isMe
                      ? null
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMe ? 10 : 4),
                    topRight: Radius.circular(isMe ? 4 : 10),
                    bottomLeft: const Radius.circular(10),
                    bottomRight: const Radius.circular(10),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.borderSubtle),
                  boxShadow: isMe
                      ? [
                          BoxShadow(
                            color: AppColors.mediumPurple.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: 220,
                          height: 160,
                          errorBuilder: (context, error, stack) => Container(
                            width: 220,
                            height: 120,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.deepIndigo.withValues(
                                alpha: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      if ((message.content ?? '').toString().trim().isNotEmpty)
                        const SizedBox(height: 10),
                    ],
                    if ((message.content ?? '').toString().trim().isNotEmpty)
                      Text(
                        message.content ?? '',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),

                    // Pending indicator row (timestamp optional)
                    if (isPending) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: isMe ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isMe) const SizedBox(width: 40),
        if (!isMe) const SizedBox(width: 40),
      ],
    );
  }
}

class _RevealIn extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _RevealIn({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + delayMs),
      curve: Curves.easeOut,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}
