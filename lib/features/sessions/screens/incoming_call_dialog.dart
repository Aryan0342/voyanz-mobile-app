import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

class IncomingCallDialog extends ConsumerWidget {
  const IncomingCallDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingCall = ref.watch(incomingCallProvider);

    if (incomingCall == null) {
      return const SizedBox.shrink();
    }

    final icon = incomingCall.type == 'video'
        ? Icons.videocam
        : incomingCall.type == 'phone'
        ? Icons.phone
        : Icons.chat_bubble_outline;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: AppGradients.accent,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: Icon(icon, size: 34, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Incoming ${incomingCall.type} call',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            incomingCall.customerFullname ?? 'Customer',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (incomingCall.tool != null) ...[
            const SizedBox(height: 4),
            Text(
              incomingCall.tool!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleReject(context, ref, incomingCall),
                  icon: const Icon(Icons.call_end),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleAccept(context, ref, incomingCall),
                  icon: const Icon(Icons.call),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.mediumPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAccept(BuildContext context, WidgetRef ref, IncomingCall call) {
    final ws = ref.read(webSocketServiceProvider);
    final notifier = ref.read(incomingCallProvider.notifier);

    // Send session_callaccepted to backend
    ws.send('session_callaccepted', {
      'callParams': call.toCallParams(),
      'isGroupSession': false,
    });

    // Clear the incoming call notification
    notifier.clear();

    // Close dialog
    Navigator.of(context).pop();

    // The professional will then receive session_started event
    // which triggers navigation to the video/phone/chat screen
  }

  void _handleReject(BuildContext context, WidgetRef ref, IncomingCall call) {
    final ws = ref.read(webSocketServiceProvider);
    final notifier = ref.read(incomingCallProvider.notifier);
    final isProfessional =
        ref.read(authStateProvider).valueOrNull?.isProfessional ?? false;

    ws.send('session_callrejected', {
      'callParams': call.toCallParams(),
      'who': isProfessional ? 'professional' : 'customer',
    });

    notifier.clear();
    Navigator.of(context).pop();
  }
}
