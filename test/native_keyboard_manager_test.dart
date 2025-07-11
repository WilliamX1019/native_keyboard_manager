import 'package:flutter_test/flutter_test.dart';
import 'package:native_keyboard_manager/native_keyboard_manager.dart';
import 'package:native_keyboard_manager/native_keyboard_manager_platform_interface.dart';
import 'package:native_keyboard_manager/native_keyboard_manager_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeKeyboardManagerPlatform
    with MockPlatformInterfaceMixin
    implements NativeKeyboardManagerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeKeyboardManagerPlatform initialPlatform = NativeKeyboardManagerPlatform.instance;

  test('$MethodChannelNativeKeyboardManager is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeKeyboardManager>());
  });

  test('getPlatformVersion', () async {
    NativeKeyboardManager nativeKeyboardManagerPlugin = NativeKeyboardManager();
    MockNativeKeyboardManagerPlatform fakePlatform = MockNativeKeyboardManagerPlatform();
    NativeKeyboardManagerPlatform.instance = fakePlatform;

    expect(await nativeKeyboardManagerPlugin.getPlatformVersion(), '42');
  });
}
