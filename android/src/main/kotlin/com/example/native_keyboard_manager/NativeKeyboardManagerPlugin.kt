package com.example.native_keyboard_manager

import android.app.Activity
import android.content.Context
import android.graphics.Rect
import android.view.View
import android.view.ViewTreeObserver
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

// 实现了 FlutterPlugin (引擎生命周期), MethodCallHandler (方法调用), ActivityAware (Activity生命周期)
class NativeKeyboardManagerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var methodChannel: MethodChannel
    private lateinit var visibilityEventChannel: EventChannel
    private lateinit var heightEventChannel: EventChannel
    private var activity: Activity? = null
    
    // 分别为两个流管理独立的 EventSink
    private var heightEventSink: EventChannel.EventSink? = null
    private var visibilityEventSink: EventChannel.EventSink? = null

    private var rootView: View? = null
    // 使用 OnGlobalLayoutListener 监听布局变化来计算键盘高度
    private var heightListener: ViewTreeObserver.OnGlobalLayoutListener? = null


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // 设置 MethodChannel
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.plugins/native_keyboard_manager")
        methodChannel.setMethodCallHandler(this)

        // 设置可见性流的 EventChannel，并为其分配一个独立的 StreamHandler
        visibilityEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.plugins/native_keyboard_manager/visibility_stream")
        visibilityEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                visibilityEventSink = events
                // 如果 Activity 已经存在，则立即开始监听
                activity?.let { setKeyboardVisibilityListener(it) }
            }
            override fun onCancel(arguments: Any?) {
                // 停止监听并清理资源
                activity?.let { clearKeyboardVisibilityListener(it) }
                visibilityEventSink = null
            }
        })

        // 设置高度流的 EventChannel，并为其分配另一个独立的 StreamHandler
        heightEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.plugins/native_keyboard_manager/height_stream")
        heightEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                heightEventSink = events
                // 如果 Activity 已经存在，则立即开始监听
                activity?.let { setupHeightListener() }
            }
            override fun onCancel(arguments: Any?) {
                // 停止监听并清理资源
                clearHeightListener()
                heightEventSink = null
            }
        })
    }
    
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        visibilityEventChannel.setStreamHandler(null)
        heightEventChannel.setStreamHandler(null)
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
    
    // --- ActivityAware 实现 ---
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        // 当 Activity 附加时，如果已有监听器在等待，则启动它们
        if (visibilityEventSink != null) {
            setKeyboardVisibilityListener(binding.activity)
        }
        if (heightEventSink != null) {
            setupHeightListener()
        }
    }

    override fun onDetachedFromActivity() {
        // 当 Activity 分离时，清理所有与 Activity 相关的监听器和引用
        clearHeightListener()
        clearKeyboardVisibilityListener(activity)
        heightEventSink = null
        visibilityEventSink = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }
    
    // --- 私有方法 ---
    private fun dismissKeyboard() {
        val currentActivity = activity ?: return
        val inputMethodManager = currentActivity.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val focusedView: View? = currentActivity.currentFocus
        // 必须有焦点视图才能隐藏
        if (focusedView != null) {
            inputMethodManager.hideSoftInputFromWindow(focusedView.windowToken, 0)
        }
    }

    private fun showKeyboard() {
        val currentActivity = activity ?: return
        val inputMethodManager = currentActivity.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        var view = currentActivity.currentFocus
        if (view == null) {
            // 如果没有焦点视图，尝试使用根视图作为后备
            view = currentActivity.window.decorView.rootView
        }
        inputMethodManager.showSoftInput(view, InputMethodManager.SHOW_IMPLICIT)
    }

    // 使用现代的 WindowInsets API 监听键盘可见性，这是官方推荐的方式
    private fun setKeyboardVisibilityListener(activity: Activity) {
        val rootView = activity.window.decorView
        ViewCompat.setOnApplyWindowInsetsListener(rootView) { _, insets ->
            val isVisible = insets.isVisible(WindowInsetsCompat.Type.ime())
            visibilityEventSink?.success(isVisible)
            insets
        }
    }
    
    // 通过监听全局布局变化来计算键盘高度
    private fun setupHeightListener() {
        rootView = activity?.window?.decorView?.rootView
        heightListener = ViewTreeObserver.OnGlobalLayoutListener {
            val rect = Rect()
            rootView?.getWindowVisibleDisplayFrame(rect)
            val screenHeight = rootView?.height ?: 0
            // 键盘高度 = 屏幕总高度 - 可见区域底部
            val keypadHeight = screenHeight - rect.bottom
            // 确保高度非负，以防布局抖动
            if (keypadHeight >= 0) {
                heightEventSink?.success(keypadHeight.toDouble())
            }
        }
        rootView?.viewTreeObserver?.addOnGlobalLayoutListener(heightListener)
    }

    private fun clearKeyboardVisibilityListener(activity: Activity?) {
        activity?.window?.decorView?.let {
            ViewCompat.setOnApplyWindowInsetsListener(it, null)
        }
    }
    
    private fun clearHeightListener() {
        heightListener?.let {
            rootView?.viewTreeObserver?.removeOnGlobalLayoutListener(it)
        }
        heightListener = null
        rootView = null
    }
}