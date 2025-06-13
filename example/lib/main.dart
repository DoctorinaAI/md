// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';

void main() => runZonedGuarded<void>(
      () => runApp(const App()),
      (e, s) => print(e),
    );

/// {@template app}
/// App widget.
/// {@endtemplate}
class App extends StatelessWidget {
  /// {@macro app}
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Markdown',
        themeMode: ThemeMode.system,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: const HomeScreen(),
      );
}

/// {@template home_screen}
/// HomeScreen widget.
/// {@endtemplate}
class HomeScreen extends StatefulWidget {
  /// {@macro home_screen}
  const HomeScreen({
    super.key, // ignore: unused_element
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State for widget HomeScreen.
class _HomeScreenState extends State<HomeScreen> {
  final MultiChildLayoutDelegate _layoutDelegate = _HomeScreenLayoutDelegate();
  final TextEditingController _inputController = TextEditingController();
  final ValueNotifier<String> _outputController = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _outputController.value = _inputController.text;
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _inputController.dispose();
    _outputController.dispose();
  }

  void _onInputChanged() {
    // Handle input changes
    _outputController.value = _inputController.text;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Markdown'),
        ),
        body: SafeArea(
          child: CustomMultiChildLayout(
            delegate: _layoutDelegate,
            children: <Widget>[
              LayoutId(
                id: 0,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Positioned.fill(
                          child: TextField(
                            controller: _inputController,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '____________________________________\n'
                                  '______________________________\n'
                                  '__________________________\n'
                                  '______________________________\n'
                                  '____________________________________\n'
                                  '________________________\n'
                                  '________________________________________\n'
                                  '______________________________\n'
                                  '________________________\n'
                                  '__________________________________________\n'
                                  '______________________________\n',
                            ),
                          ),
                        ),
                        /* Align(
                          alignment: Alignment.topRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              IconButton.filledTonal(
                                icon: const Text(
                                  '1️⃣',
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 1.0,
                                  ),
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Text(
                                  '2️⃣',
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 1.0,
                                  ),
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Text(
                                  '3️⃣',
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 1.0,
                                  ),
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Text(
                                  '4️⃣',
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 1.0,
                                  ),
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ), */
                      ],
                    ),
                  ),
                ),
              ),
              LayoutId(
                id: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ValueListenableBuilder(
                      valueListenable: _outputController,
                      builder: (context, value, child) => Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _HomeScreenLayoutDelegate extends MultiChildLayoutDelegate {
  _HomeScreenLayoutDelegate();

  @override
  void performLayout(Size size) {
    if (size.width >= size.height) {
      final width = size.width / 2;
      final constraints =
          BoxConstraints.tightFor(width: width, height: size.height);
      layoutChild(0, constraints);
      layoutChild(1, constraints);
      positionChild(0, Offset.zero);
      positionChild(1, Offset(width, 0));
    } else {
      final height = size.height / 2;
      final constraints =
          BoxConstraints.tightFor(width: size.width, height: height);
      layoutChild(0, constraints);
      layoutChild(1, constraints);
      positionChild(0, Offset.zero);
      positionChild(1, Offset(0, height));
    }
  }

  @override
  bool shouldRelayout(covariant _HomeScreenLayoutDelegate oldDelegate) => false;
}
