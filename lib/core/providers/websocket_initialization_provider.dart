import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/network/websocket_service.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';

/// Initializes WebSocket connection at app startup
/// Call this in your app's root widget to ensure WebSocket is connected
/// as soon as authentication completes
final webSocketInitializationProvider = FutureProvider<void>((ref) async {
  // Get the WebSocket service and connect
  final ws = ref.watch(webSocketServiceProvider);

  // Start connection
  await ws.connect();
});
