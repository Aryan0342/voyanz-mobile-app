import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/core/utils/date_utils.dart' as date_utils;
import 'package:voyanz/features/chat/models/chat_models.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/chat/providers/chat_messages_notifier.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';

String _resolveMediaUrl(String raw) {
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final normalized = raw.startsWith('/') ? raw : '/$raw';
  return '${EnvConfig.current.baseUrl}$normalized';
}

String _formatTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  final local = date_utils.DateUtils.parisToLocal(dateStr);
  if (local == null) return '';
  final hr = local.hour;
  final min = local.minute.toString().padLeft(2, '0');
  final period = hr >= 12 ? 'PM' : 'AM';
  final hr12 = hr == 0 ? 12 : (hr > 12 ? hr - 12 : hr);
  return '$hr12:$min $period';
}

class ChatMessagesScreen extends ConsumerStatefulWidget {
  final String chgrId;
  final String? seId;
  final String? coId;

  const ChatMessagesScreen({
    super.key,
    required this.chgrId,
    this.seId,
    this.coId,
  });

  @override
  ConsumerState<ChatMessagesScreen> createState() => _ChatMessagesScreenState();
}

class _ChatMessagesScreenState extends ConsumerState<ChatMessagesScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _readMessageIds = <String>{};
  bool _sending = false;
  bool _sendingImage = false;
  bool _sessionEndedHandled = false;

  bool get _hasSession =>
      widget.seId != null && widget.seId!.trim().isNotEmpty;

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
              ref.read(translationsProvider).sendMessageFailed('Please try again.'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static const _maxImageBytes = 5 * 1024 * 1024;

  /// Images chosen by the user, shown as previews above the composer until
  /// they press send (WhatsApp-style).
  final List<File> _pendingImages = [];

  /// Sniffs image type from magic bytes instead of trusting the filename:
  /// many Android gallery pickers return names WITHOUT a usable extension
  /// (e.g. "IMG_20260823"), which used to abort the upload silently.
  String? _sniffImageMime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpeg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'gif';
    }
    return null;
  }

  void _showImageError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _pickImages() async {
    if (_sendingImage) return;
    try {
      debugPrint('[chat-image] opening multi picker...');
      final picked = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked.isEmpty) {
        debugPrint('[chat-image] picker cancelled');
        return;
      }
      debugPrint('[chat-image] picked ${picked.length} image(s)');
      if (!mounted) return;
      setState(() {
        _pendingImages.addAll(picked.map((x) => File(x.path)));
      });
    } catch (e) {
      debugPrint('[chat-image] PICK FAILED: $e');
      _showImageError('Could not open gallery: $e');
    }
  }

  Future<void> _sendPendingImages() async {
    if (_pendingImages.isEmpty || _sendingImage) return;
    setState(() => _sendingImage = true);
    var failed = 0;
    try {
      // Copy so we can mutate the live list safely while iterating.
      final items = List<File>.from(_pendingImages);
      for (final file in items) {
        try {
          final bytes = await file.readAsBytes();
          final mime = _sniffImageMime(bytes);
          if (mime == null) {
            debugPrint('[chat-image] skip ${file.path}: unknown format');
            failed++;
            if (mounted) setState(() => _pendingImages.remove(file));
            continue;
          }
          if (bytes.length > _maxImageBytes) {
            debugPrint('[chat-image] skip ${file.path}: >5MB');
            failed++;
            if (mounted) setState(() => _pendingImages.remove(file));
            continue;
          }

          final b64 = base64Encode(bytes);
          debugPrint(
            '[chat-image] sending $mime (${bytes.length} bytes)',
          );
          await ref
              .read(chatMessagesNotifierProvider(widget.chgrId).notifier)
              .sendImage('data:image/$mime;base64,$b64');
          debugPrint('[chat-image] send OK');
          if (mounted) setState(() => _pendingImages.remove(file));
        } catch (e) {
          failed++;
          debugPrint('[chat-image] SEND FAILED: $e');
        }
      }
      if (failed > 0) {
        _showImageError('$failed image(s) failed to send. Try again.');
      }
    } finally {
      if (mounted) setState(() => _sendingImage = false);
    }
  }

  /// Send button: images first (if any), then the typed text message.
  Future<void> _onSendPressed() async {
    if (_sending || _sendingImage) return;
    if (_pendingImages.isNotEmpty) {
      await _sendPendingImages();
      if (!mounted) return;
    }
    if (_msgCtrl.text.trim().isNotEmpty) {
      await _send();
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

    ref.read(chatUnreadCountsProvider.notifier).state = {
      ...ref.read(chatUnreadCountsProvider),
      widget.chgrId: 0,
    };
    // Re-fetch the groups list so the REST-side `lastmessageread` flag
    // refreshes too — otherwise the fallback unread dot stays lit.
    ref.invalidate(chatGroupsProvider);
  }

  Future<void> _confirmEndSession() async {
    final t = ref.read(translationsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.endSessionConfirmTitle),
        content: Text(t.endSessionConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              t.endSession,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _sessionEndedHandled = true;
    final ws = ref.read(webSocketServiceProvider);
    if (!ws.isConnected) {
      await ws.connect();
    }
    ws.send('session_stop', {'se_id': widget.seId});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.sessionEnded),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) {
      context.go('/home');
    }
  }

  void _handleSessionEnded(String message) {
    if (_sessionEndedHandled || !mounted) return;
    _sessionEndedHandled = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      chatMessagesNotifierProvider(widget.chgrId),
    );
    final t = ref.watch(translationsProvider);

    if (_hasSession) {
      ref.listen<AsyncValue<SessionStatus>>(
        sessionStatusLivePollingProvider(widget.seId!),
        (_, next) {
          next.whenOrNull(
            data: (status) {
              if (!mounted || !status.isTerminal) return;
              _handleSessionEnded(
                status.localizedMessage(
                  ref.read(translationsProvider),
                  isProfessional:
                      ref.read(authStateProvider).valueOrNull?.isProfessional ??
                      false,
                ),
              );
            },
          );
        },
      );
    }

    String? otherUserName;
    messagesAsync.whenData((messages) {
      final currentUser = ref.read(authStateProvider).valueOrNull;
      for (final m in messages) {
        if (m.senderCoId != null && m.senderCoId != currentUser?.coId) {
          otherUserName = m.senderName;
          break;
        }
      }
    });
    final displayTitle = otherUserName ?? t.conversation;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.accent,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Active now',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mediumPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_hasSession)
            _ChatSessionEndBar(
              sessionId: widget.seId!,
              onEnd: _confirmEndSession,
            ),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[messages.length - 1 - i];
                      final currentUser = ref
                          .watch(authStateProvider)
                          .valueOrNull;
                      final isMe =
                          (msg.senderCoId != null &&
                          msg.senderCoId == currentUser?.coId);
                          
                      bool showTime = true;
                      if (i > 0) {
                        final nextMsgDown = messages[messages.length - 1 - (i - 1)];
                        if (nextMsgDown.senderCoId == msg.senderCoId) {
                           showTime = false;
                        }
                      }

                      return _RevealIn(
                        delayMs: i * 18,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: showTime ? 16 : 4),
                          child: _MessageBubble(message: msg, isMe: isMe, showTime: showTime),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // ── Message input ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              color: const Color(0xFFF8F9FA),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_pendingImages.isNotEmpty) ...[
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pendingImages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final file = _pendingImages[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    file,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _pendingImages.removeAt(index));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.black54),
                              onPressed:
                                  (_sending || _sendingImage)
                                      ? null
                                      : _pickImages,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                maxLines: null,
                                textInputAction: TextInputAction.newline,
                                style: GoogleFonts.manrope(
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: GoogleFonts.manrope(
                                    color: Colors.black45,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: GestureDetector(
                                onTap: (_sending || _sendingImage)
                                    ? null
                                    : _onSendPressed,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: (_sending || _sendingImage)
                                        ? null
                                        : const LinearGradient(
                                            colors: [
                                              Color(0xFF9B3366),
                                              Color(0xFFB83280),
                                            ],
                                          ),
                                    color: (_sending || _sendingImage)
                                        ? AppColors.textMuted
                                        : null,
                                  ),
                                  child: (_sending || _sendingImage)
                                      ? const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          _pendingImages.isNotEmpty &&
                                                  _msgCtrl.text.trim().isEmpty
                                              ? Icons.image
                                              : Icons.send,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showTime;

  const _MessageBubble({required this.message, required this.isMe, this.showTime = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isMe ? const LinearGradient(
                    colors: [Color(0xFF9B3366), Color(0xFFB83280)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ) : null,
                  color: isMe ? null : const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
                              borderRadius: BorderRadius.circular(16),
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
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: isMe ? Colors.white : const Color(0xFF2A2A2A),
                          height: 1.4,
                        ),
                      ),

                    if (isPending) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
            ),
          ],
        ),
        if (showTime)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              _formatTime(message.createdAt),
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
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

class _ChatSessionEndBar extends ConsumerWidget {
  final String sessionId;
  final VoidCallback onEnd;

  const _ChatSessionEndBar({
    required this.sessionId,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return Material(
      color: AppColors.error,
      child: SafeArea(
        bottom: false,
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '#$sessionId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEnd,
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.white, size: 18),
                label: Text(
                  t.endSession,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
