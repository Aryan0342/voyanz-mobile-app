import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';

class IncomingCallDialog extends ConsumerWidget {
  const IncomingCallDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingCall = ref.watch(incomingCallProvider);

    if (incomingCall == null) {
      return const SizedBox.shrink();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              incomingCall.type == 'video'
                  ? Icons.videocam
                  : incomingCall.type == 'phone'
                  ? Icons.phone
                  : Icons.chat,
              size: 48,
              color: Colors.blue,
            ),
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
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (incomingCall.tool != null) ...[
            const SizedBox(height: 4),
            Text(
              incomingCall.tool!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleAccept(context, ref, incomingCall),
              icon: const Icon(Icons.call),
              label: const Text('Start'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
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
}
