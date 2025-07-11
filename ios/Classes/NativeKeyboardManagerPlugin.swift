// ios/Classes/SwiftNativeKeyboardManagerPlugin.swift
import Flutter
import UIKit

public class SwiftNativeKeyboardManagerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftNativeKeyboardManagerPlugin()

        let methodChannel = FlutterMethodChannel(name: "com.plugins/native_keyboard_manager", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(name: "com.plugins/native_keyboard_manager/visibility_stream", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "dismissKeyboard":
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            result(nil)
        case "showKeyboard":
            // iOS does not have a generic API to "show" the keyboard.
            // It is automatically shown when a text field becomes the first responder.
            // We return success to maintain API consistency.
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
            
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        self.eventSink = nil
        return nil
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        eventSink?(true)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        eventSink?(false)
    }
}