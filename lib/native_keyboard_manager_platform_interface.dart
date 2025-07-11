import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_keyboard_manager_method_channel.dart';

abstract class NativeKeyboardManagerPlatform extends PlatformInterface {
  /// Constructs a NativeKeyboardManagerPlatform.
  NativeKeyboardManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeKeyboardManagerPlatform _instance = MethodChannelNativeKeyboardManager();

  /// The default instance of [NativeKeyboardManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeKeyboardManager].
  static NativeKeyboardManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeKeyboardManagerPlatform] when
  /// they register themselves.
  static set instance(NativeKeyboardManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
