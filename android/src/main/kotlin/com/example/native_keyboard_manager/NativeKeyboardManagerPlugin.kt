// android/src/main/kotlin/com/example/native_keyboard_manager/NativeKeyboardManagerPlugin.kt
package com.example.native_keyboard_manager

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.inputmethod.InputMethodManager
import androidx.annotation.NonNull
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class NativeKeyboardManagerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.plugins/native_keyboard_manager")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.plugins/native_keyboard_manager/visibility_stream")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "dismissKeyboard" -> {
                dismissKeyboard()
                result.success(null)
            }
            "showKeyboard" -> {
                showKeyboard()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        activity?.let { setKeyboardVisibilityListener(it) }
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
        activity?.let { clearKeyboardVisibilityListener(it) }
    }
    
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (eventSink != null) {
            setKeyboardVisibilityListener(binding.activity)
        }
    }

    override fun onDetachedFromActivity() {
        activity?.let { clearKeyboardVisibilityListener(it) }
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    private fun dismissKeyboard() {
        val currentActivity = activity ?: return
        val inputMethodManager = currentActivity.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val focusedView: View? = currentActivity.currentFocus
        if (focusedView != null) {
            inputMethodManager.hideSoftInputFromWindow(focusedView.windowToken, 0)
        }
    }

    private fun showKeyboard() {
        val currentActivity = activity ?: return
        val inputMethodManager = currentActivity.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val focusedView: View? = currentActivity.currentFocus
        if (focusedView != null) {
            inputMethodManager.showSoftInput(focusedView, InputMethodManager.SHOW_IMPLICIT)
        }
    }

    private fun setKeyboardVisibilityListener(activity: Activity) {
        val rootView = activity.window.decorView
        ViewCompat.setOnApplyWindowInsetsListener(rootView) { _, insets ->
            val isVisible = insets.isVisible(WindowInsetsCompat.Type.ime())
            eventSink?.success(isVisible)
            insets
        }
    }

    private fun clearKeyboardVisibilityListener(activity: Activity) {
        val rootView = activity.window.decorView
        ViewCompat.setOnApplyWindowInsetsListener(rootView, null)
    }
}