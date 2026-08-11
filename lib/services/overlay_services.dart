import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OverlayService {
  static const _platform = MethodChannel('com.yourapp/overlay');

  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _platform.invokeMethod('initializeOverlay');
    }
  }

  static Future<void> showIncomingCall({
    required String callerId,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) async {
    if (Platform.isAndroid) {
      await _platform.invokeMethod('showIncomingCall', {
        'callerId': callerId,
      });
    }
  }
}
