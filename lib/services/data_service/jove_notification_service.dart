// lib/features/notification/data/services/jove_notification_service.dart
import 'package:flutter/services.dart';
import 'package:tcc_3/common/models/notification_listener.dart';

class JoveNotificationService {
  static const _eventChannel = EventChannel('jove_notification_event_channel');

  static Stream<NotificationEvent> get notificationStream {
    return _eventChannel.receiveBroadcastStream().map(
      (event) => NotificationEvent.fromMap(event),
    );
  }
}
