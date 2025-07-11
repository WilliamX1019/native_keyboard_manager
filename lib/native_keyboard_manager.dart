
import 'native_keyboard_manager_platform_interface.dart';

class NativeKeyboardManager {
  Future<String?> getPlatformVersion() {
    return NativeKeyboardManagerPlatform.instance.getPlatformVersion();
  }
}
