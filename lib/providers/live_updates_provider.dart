import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/websocket_service.dart';

final wsEventsProvider = StreamProvider<WsEvent>((ref) {
  if (ApiConstants.frontendOnly) {
    return const Stream<WsEvent>.empty();
  }
  return WebSocketService.instance.events;
});

bool shouldInvalidateForWsEvent(String eventType) {
  return switch (eventType) {
    'sync_complete' || 'student_registered' || 'device_connected' => true,
    'score_recorded' || 'progress_updated' => true,
    'content_updated' => true,
    _ => false,
  };
}
