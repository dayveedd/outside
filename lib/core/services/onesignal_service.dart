import 'dart:async';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../constants/constants.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  final StreamController<String> _deepLinkController = StreamController<String>.broadcast();
  Stream<String> get deepLinkStream => _deepLinkController.stream;

  Future<void> initialize() async {
    // Enable verbose logging in development (optional, can be disabled)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize SDK
    OneSignal.initialize(AppConstants.oneSignalAppId);

    // Prompt for notification permissions (recommended for onboarding)
    await OneSignal.Notifications.requestPermission(true);

    // Configure notification click event listener
    OneSignal.Notifications.addClickListener((event) {
      final additionalData = event.notification.additionalData;
      if (additionalData != null && additionalData.containsKey('lessonId')) {
        final lessonId = additionalData['lessonId'] as String;
        _deepLinkController.add(lessonId);
      }
    });
  }

  void login(String userId) {
    OneSignal.login(userId);
  }

  void logout() {
    OneSignal.logout();
  }

  void dispose() {
    _deepLinkController.close();
  }
}
