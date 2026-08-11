import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> initialize() async {
    debugPrint('NotificationService initialized');
  }

  static Future<void> showIncomingCallNotification({
    required String callerId,
    required String callId,
  }) async {
    debugPrint('Incoming call from: $callerId');
  }
}
