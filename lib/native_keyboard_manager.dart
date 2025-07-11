// lib/native_keyboard_manager.dart

import 'dart:async';
import 'package:flutter/services.dart';

// 1. 定义一个枚举来表示键盘状态，这比布尔值更清晰
enum KeyboardVisibilityStatus { shown, hidden }

class NativeKeyboardManager {
  // MethodChannel 用于一次性调用 (保持不变)
  static const MethodChannel _methodChannel = MethodChannel('com.plugins/native_keyboard_manager');

  // 2. 新增一个 EventChannel 用于事件流
  static const EventChannel _visibilityChannel = EventChannel('com.plugins/native_keyboard_manager/visibility_stream');

  // 3. 定义一个私有的、可空的 Stream 变量用于缓存
  static Stream<KeyboardVisibilityStatus>? _keyboardVisibilityStream;

  /// Dismisses the native keyboard on both Android and iOS.
  static Future<void> dismissKeyboard() async {
    try {
      await _methodChannel.invokeMethod('dismissKeyboard');
    } on PlatformException catch (e) {
      print("Failed to dismiss keyboard via native_keyboard_manager: '${e.message}'.");
    }
  }
  static Future<void> showKeyboard() async {
    try {
      // 新增一个 'showKeyboard' 方法调用
      await _methodChannel.invokeMethod('showKeyboard');
    } on PlatformException catch (e) {
      print("Failed to show keyboard via native_keyboard_manager: '${e.message}'.");
    }
  }
  /// A stream that emits the visibility status of the native keyboard.
  ///
  /// Emits [KeyboardVisibilityStatus.shown] when the keyboard appears
  /// and [KeyboardVisibilityStatus.hidden] when it disappears.
  static Stream<KeyboardVisibilityStatus> get keyboardVisibilityStream {
    // 4. 使用空值合并运算符实现单例模式，确保 Stream 只被创建一次
    _keyboardVisibilityStream ??= _visibilityChannel
        .receiveBroadcastStream()
        .map((event) => event is bool && event ? KeyboardVisibilityStatus.shown : KeyboardVisibilityStatus.hidden);
    return _keyboardVisibilityStream!;
  }
}