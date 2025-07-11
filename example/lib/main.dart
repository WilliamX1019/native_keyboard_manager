import 'package:flutter/material.dart';

// 导入我们自己实现的插件文件
import 'package:native_keyboard_manager/native_keyboard_manager.dart'; // ⚠️ 确保包名正确

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector 用于点击屏幕任何地方时关闭键盘
    return GestureDetector(
      onTap: () {
        // 调用我们插件的 dismissKeyboard 方法
        NativeKeyboardManager.dismissKeyboard();
      },
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Native Keyboard Manager Test'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Center(
              // 使用 StreamBuilder 来监听我们统一的键盘信息流
              child: StreamBuilder<KeyboardInfo>(
                // 监听 onKeyboardInfoChanged 流
                stream: NativeKeyboardManager.onKeyboardInfoChanged,
                // 提供一个初始数据，避免在流发出第一个事件前 snapshot.data 为 null
                initialData: const KeyboardInfo(isVisible: false, height: 0.0),
                builder: (context, snapshot) {
                  // 从 snapshot 中获取最新的 KeyboardInfo 对象
                  // 使用 ! 是安全的，因为我们提供了 initialData
                  final keyboardInfo = snapshot.data!;
                  final isVisible = keyboardInfo.isVisible;
                  final height = keyboardInfo.height;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 第一个信息框，显示高度和可见状态的文本描述
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '键盘高度: ${height.toStringAsFixed(1)}px',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '可见状态: ${isVisible ? '显示' : '隐藏'}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.blue.shade600),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 第二个信息框，根据可见性改变颜色
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isVisible
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Keyboard Status: ${isVisible ? 'SHOWN' : 'HIDDEN'}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isVisible
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Controlled TextField',
                          hintText: '点击下方按钮来获取焦点',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.keyboard_arrow_up),
                        label: const Text('Show Keyboard'),
                        onPressed: () {
                          // 先让输入框获取焦点
                          _focusNode.requestFocus();
                          // 然后调用插件方法（在Android上更有用）
                          NativeKeyboardManager.showKeyboard();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        label: const Text('Dismiss Keyboard'),
                        // 直接引用插件的静态方法
                        onPressed: NativeKeyboardManager.dismissKeyboard,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            )
          ),
        ),
      ),
    );
  }
}