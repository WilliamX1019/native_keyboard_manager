// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:native_keyboard_manager/native_keyboard_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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
    return GestureDetector(
      // Tap anywhere on the screen to dismiss the keyboard
      onTap: () {
        NativeKeyboardManager.dismissKeyboard();
        // It's good practice to also unfocus from Flutter's perspective
        // FocusScope.of(context).unfocus();
      },
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Native Keyboard Manager'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder<KeyboardVisibilityStatus>(
                    stream: NativeKeyboardManager.keyboardVisibilityStream,
                    initialData: KeyboardVisibilityStatus.hidden,
                    builder: (context, snapshot) {
                      final status = snapshot.data!;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: status == KeyboardVisibilityStatus.shown
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Keyboard Status: ${status.name.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: status == KeyboardVisibilityStatus.shown
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Controlled TextField',
                      hintText: 'Tap the button below to focus',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    label: const Text('Show Keyboard'),
                    onPressed: () {
                      _focusNode.requestFocus();
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
                    onPressed: NativeKeyboardManager.dismissKeyboard,
                     style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}