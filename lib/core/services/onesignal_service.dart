import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../constants/constants.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  final StreamController<String> _deepLinkController = StreamController<String>.broadcast();
  Stream<String> get deepLinkStream => _deepLinkController.stream;

  final StreamController<String> _subscriptionIdController = StreamController<String>.broadcast();
  Stream<String> get subscriptionIdStream => _subscriptionIdController.stream;

  final ValueNotifier<bool> permissionNotifier = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(AppConstants.oneSignalAppId);

    await refreshPermission();

    OneSignal.Notifications.addPermissionObserver((state) {
      permissionNotifier.value = state;
    });

    OneSignal.User.pushSubscription.addObserver((state) {
      final id = state.current.id;
      if (id != null && id.isNotEmpty && !id.startsWith('local-')) {
        _subscriptionIdController.add(id);
      }
      final optedIn = state.current.optedIn;
      if (optedIn) {
        permissionNotifier.value = true;
      }
    });

    final currentId = OneSignal.User.pushSubscription.id;
    if (currentId != null && currentId.isNotEmpty && !currentId.startsWith('local-')) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _subscriptionIdController.add(currentId);
      });
    }

    OneSignal.Notifications.addClickListener((event) {
      final additionalData = event.notification.additionalData;
      if (additionalData != null && additionalData.containsKey('lessonId')) {
        final lessonId = additionalData['lessonId'] as String;
        _deepLinkController.add(lessonId);
      }
    });
  }

  Future<bool> promptNotificationPermission() async {
    final granted = await OneSignal.Notifications.requestPermission(true);
    await refreshPermission();
    return permissionNotifier.value || granted;
  }

  Future<void> refreshPermission() async {
    try {
      final nativePerm = await OneSignal.Notifications.permissionNative();
      final bool isNativeAuthorized = nativePerm == OSNotificationPermission.authorized ||
          nativePerm == OSNotificationPermission.provisional ||
          nativePerm == OSNotificationPermission.ephemeral;
      final bool isOptedIn = OneSignal.User.pushSubscription.optedIn ?? false;
      final bool isPermGranted = OneSignal.Notifications.permission;
      permissionNotifier.value = isNativeAuthorized || isOptedIn || isPermGranted;
    } catch (_) {
      permissionNotifier.value =
          (OneSignal.User.pushSubscription.optedIn ?? false) || OneSignal.Notifications.permission;
    }
  }

  bool get hasPermission =>
      permissionNotifier.value ||
      (OneSignal.User.pushSubscription.optedIn ?? false) ||
      OneSignal.Notifications.permission;

  void login(String userId) {
    OneSignal.login(userId);
  }

  void logout() {
    OneSignal.logout();
  }

  void syncStreakTags({required int streakCount, required bool completedToday}) {
    OneSignal.User.addTags({
      'streak': streakCount.toString(),
      'completed_today': completedToday.toString(),
    });
  }

  void dispose() {
    _deepLinkController.close();
    _subscriptionIdController.close();
    permissionNotifier.dispose();
  }
}
