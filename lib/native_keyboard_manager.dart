import 'dart:async';
import 'package:flutter/services.dart';

/// 一个封装了键盘可见性和高度的数据类。
class KeyboardInfo {
  /// 键盘当前是否可见。
  final bool isVisible;
  
  /// 键盘的像素高度。
  final double height;

  const KeyboardInfo({
    required this.isVisible,
    required this.height,
  });

  @override
  String toString() {
    return 'KeyboardInfo(isVisible: $isVisible, height: ${height.toStringAsFixed(2)})';
  }
}

/// 提供了与原生键盘交互的静态方法和流。
class NativeKeyboardManager {
  // 私有构造函数，防止外部实例化。
  NativeKeyboardManager._();

  // 用于调用原生方法的 MethodChannel。
  static const MethodChannel _methodChannel =
      MethodChannel('com.plugins/native_keyboard_manager');

  // 用于监听原生事件的 EventChannel。
  static const EventChannel _visibilityChannel =
      EventChannel('com.plugins/native_keyboard_manager/visibility_stream');
  static const EventChannel _heightChannel =
      EventChannel('com.plugins/native_keyboard_manager/height_stream');

  // 这个控制器将管理并广播我们合并后的流。
  // 设置 onListen 和 onCancel 回调来管理资源。
  static final StreamController<KeyboardInfo> _controller =
      StreamController<KeyboardInfo>.broadcast(
    onListen: _onListen,
    onCancel: _onCancel,
  );

  // 用于持有对底层原生流的订阅。
  static StreamSubscription<bool>? _visibilitySubscription;
  static StreamSubscription<double>? _heightSubscription;

  // 用于存储从每个流接收到的最新值。
  static bool? _latestVisibility;
  static double? _latestHeight;
  
  /// 一个广播流，当键盘的可见性或高度发生变化时，会发出一个 [KeyboardInfo] 对象。
  static Stream<KeyboardInfo> get onKeyboardInfoChanged => _controller.stream;

  /// 异步请求原生平台关闭键盘。
  static Future<void> dismissKeyboard() async {
    try {
      await _methodChannel.invokeMethod('dismissKeyboard');
    } on PlatformException catch (e) {
      print("Failed to dismiss keyboard: '${e.message}'.");
    }
  }

  /// 异步请求原生平台显示键盘。
  static Future<void> showKeyboard() async {
    try {
      await _methodChannel.invokeMethod('showKeyboard');
    } on PlatformException catch (e) {
      print("Failed to show keyboard: '${e.message}'.");
    }
  }

  /// 当第一个监听者订阅我们的流时，此函数会被调用。
  static void _onListen() {
    // 开始监听两个原生流。
    _visibilitySubscription = _visibilityChannel
        .receiveBroadcastStream()
        .map((event) => event as bool)
        .listen((isVisible) {
      _latestVisibility = isVisible;
      _publishCombinedEvent(); // 收到新数据后，尝试发布合并事件
    });

    _heightSubscription = _heightChannel
        .receiveBroadcastStream()
        .map((event) => event as double)
        .listen((height) {
      _latestHeight = height;
      _publishCombinedEvent(); // 收到新数据后，尝试发布合并事件
    });
  }

  /// 当最后一个监听者取消订阅时，此函数会被调用。
  static void _onCancel() {
    // 停止监听原生流以释放资源。
    _visibilitySubscription?.cancel();
    _heightSubscription?.cancel();
    // 清理引用
    _visibilitySubscription = null;
    _heightSubscription = null;
  }

  /// 检查是否已拥有来自两个流的最新数据，
  /// 如果有，则创建一个新的 [KeyboardInfo] 事件并将其添加到控制器中。
  static void _publishCombinedEvent() {
    // 确保两个值都已接收到，避免发送不完整的数据。
    if (_latestVisibility != null && _latestHeight != null) {
      final double correctedHeight = _latestVisibility! ? _latestHeight! : 0.0;
      _controller.add(
        KeyboardInfo(
          isVisible: _latestVisibility!,
          height: correctedHeight,
        ),
      );
    }
  }
}