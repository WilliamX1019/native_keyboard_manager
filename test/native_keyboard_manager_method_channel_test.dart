import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_keyboard_manager/native_keyboard_manager_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNativeKeyboardManager platform = MethodChannelNativeKeyboardManager();
  const MethodChannel channel = MethodChannel('native_keyboard_manager');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
