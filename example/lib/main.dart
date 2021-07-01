import 'package:flutter/material.dart';
import 'package:shallowblue/ShallowBlue.dart';

import 'src/output_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<MyApp> {
  late ShallowBlue shallowBlue;

  @override
  void initState() {
    super.initState();
    shallowBlue = ShallowBlue();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ShallowBlue example app'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedBuilder(
                animation: shallowBlue.state,
                builder: (_, __) => Text(
                  'shallowBlue.state=${shallowBlue.state.value}',
                  key: ValueKey('shallowBlue.state'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedBuilder(
                animation: shallowBlue.state,
                builder: (_, __) => ElevatedButton(
                  onPressed: shallowBlue.state.value == ShallowBlueState.disposed
                      ? () {
                          final newInstance = ShallowBlue();
                          setState(() => shallowBlue = newInstance);
                        }
                      : null,
                  child: Text('Reset ShallowBlue instance'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Custom UCI command',
                  hintText: 'go infinite',
                ),
                onSubmitted: (value) => shallowBlue.stdin = value,
                textInputAction: TextInputAction.send,
              ),
            ),
            Wrap(
              children: [
                'd',
                'isready',
                'go infinite',
                'go movetime 3000',
                'stop',
                'quit',
              ]
                  .map(
                    (command) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () => shallowBlue.stdin = command,
                        child: Text(command),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            Expanded(
              child: OutputWidget(shallowBlue.stdout),
            ),
          ],
        ),
      ),
    );
  }
}
