import Flutter
import UIKit

public class SwiftNativeKeyboardManagerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // 注册 MethodChannel
        let methodChannel = FlutterMethodChannel(name: "com.plugins/native_keyboard_manager", binaryMessenger: registrar.messenger())
        let instance = SwiftNativeKeyboardManagerPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        // 注册可见性流的 EventChannel
        let visibilityChannel = FlutterEventChannel(name: "com.plugins/native_keyboard_manager/visibility_stream", binaryMessenger: registrar.messenger())
        visibilityChannel.setStreamHandler(KeyboardVisibilityStreamHandler())

        // 注册高度流的 EventChannel
        let heightChannel = FlutterEventChannel(name: "com.plugins/native_keyboard_manager/height_stream", binaryMessenger: registrar.messenger())
        heightChannel.setStreamHandler(KeyboardHeightStreamHandler())
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "dismissKeyboard":
            // 向整个应用发送 resignFirstResponder 动作，关闭键盘
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            result(nil)
        case "showKeyboard":
            // iOS 没有直接显示键盘的 API，这需要 TextField 自己调用 becomeFirstResponder。
            // 因此，这里是一个空操作。
            #if DEBUG
            print("showKeyboard is a no-op on iOS.")
            #endif
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - 可见性 Stream Handler
class KeyboardVisibilityStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // 添加键盘通知观察者
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // 移除观察者并清理资源
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        eventSink?(true)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        eventSink?(false)
    }
}

// MARK: - 高度 Stream Handler
class KeyboardHeightStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // keyboardWillChangeFrame 可以同时处理键盘显示和尺寸变化（例如切换语言）
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
    
    @objc private func keyboardWillChangeFrame(notification: NSNotification) {
        // 从通知中获取键盘的最终 frame
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            // 发送键盘的高度
            eventSink?(keyboardRectangle.height)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        // 键盘隐藏时，高度为 0
        eventSink?(0.0)
    }
}