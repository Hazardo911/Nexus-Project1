import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppPreferences {
  static final notifications = ValueNotifier<bool>(true);
  static final hapticFeedback = ValueNotifier<bool>(true);
  static final darkCameraPreview = ValueNotifier<bool>(false);

  static void setNotifications(bool value) => notifications.value = value;

  static void setHapticFeedback(bool value) => hapticFeedback.value = value;

  static void setDarkCameraPreview(bool value) => darkCameraPreview.value = value;
}

class AppHaptics {
  static Future<void> selection() async {
    if (!AppPreferences.hapticFeedback.value) {
      return;
    }
    await HapticFeedback.selectionClick();
  }

  static Future<void> lightImpact() async {
    if (!AppPreferences.hapticFeedback.value) {
      return;
    }
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    if (!AppPreferences.hapticFeedback.value) {
      return;
    }
    await HapticFeedback.mediumImpact();
  }
}
