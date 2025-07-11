import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_keyboard_manager_platform_interface.dart';

/// An implementation of [NativeKeyboardManagerPlatform] that uses method channels.
class MethodChannelNativeKeyboardManager extends NativeKeyboardManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_keyboard_manager');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
