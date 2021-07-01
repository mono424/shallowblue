import 'dart:async';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'ffi.dart';
import 'ShallowBlueState.dart';

/// A wrapper for C++ engine.
class ShallowBlue {
  final Completer<ShallowBlue>? completer;

  final _state = _ShallowBlueState();
  final _stdoutController = StreamController<String>.broadcast();
  final _mainPort = ReceivePort();
  final _stdoutPort = ReceivePort();

  late StreamSubscription _mainSubscription;
  late StreamSubscription _stdoutSubscription;

  ShallowBlue._({this.completer}) {
    _mainSubscription =
        _mainPort.listen((message) => _cleanUp(message is int ? message : 1));
    _stdoutSubscription = _stdoutPort.listen((message) {
      if (message is String) {
        _stdoutController.sink.add(message);
      } else {
        debugPrint('[ShallowBlue] The stdout isolate sent $message');
      }
    });
    compute(_spawnIsolates, [_mainPort.sendPort, _stdoutPort.sendPort]).then(
      (success) {
        final state = success ? ShallowBlueState.ready : ShallowBlueState.error;
        _state._setValue(state);
        if (state == ShallowBlueState.ready) {
          completer?.complete(this);
        }
      },
      onError: (error) {
        debugPrint('[ShallowBlue] The init isolate encountered an error $error');
        _cleanUp(1);
      },
    );
  }

  static ShallowBlue? _instance;

  /// Creates a C++ engine.
  ///
  /// This may throws a [StateError] if an active instance is being used.
  /// Owner must [dispose] it before a new instance can be created.
  factory ShallowBlue() {
    if (_instance != null) {
      throw new StateError('Multiple instances are not supported, yet.');
    }

    _instance = ShallowBlue._();
    return _instance!;
  }

  /// The current state of the underlying C++ engine.
  ValueListenable<ShallowBlueState> get state => _state;

  /// The standard output stream.
  Stream<String> get stdout => _stdoutController.stream;

  /// The standard input sink.
  set stdin(String line) {
    final stateValue = _state.value;
    if (stateValue != ShallowBlueState.ready) {
      throw StateError('ShallowBlue is not ready ($stateValue)');
    }

    final pointer = '$line\n'.toNativeUtf8();
    nativeStdinWrite(pointer);
    calloc.free(pointer);
  }

  /// Stops the C++ engine.
  void dispose() {
    stdin = 'quit';
  }

  void _cleanUp(int exitCode) {
    _stdoutController.close();

    _mainSubscription.cancel();
    _stdoutSubscription.cancel();

    _state._setValue(
        exitCode == 0 ? ShallowBlueState.disposed : ShallowBlueState.error);

    _instance = null;
  }
}

/// Creates a C++ engine asynchronously.
///
/// This method is different from the factory method [new ShallowBlue] that
/// it will wait for the engine to be ready before returning the instance.
Future<ShallowBlue> shallowBlueAsync() {
  if (ShallowBlue._instance != null) {
    return Future.error(StateError('Only one instance can be used at a time'));
  }

  final completer = Completer<ShallowBlue>();
  ShallowBlue._instance = ShallowBlue._(completer: completer);
  return completer.future;
}

class _ShallowBlueState extends ChangeNotifier
    implements ValueListenable<ShallowBlueState> {
  ShallowBlueState _value = ShallowBlueState.starting;

  @override
  ShallowBlueState get value => _value;

  _setValue(ShallowBlueState v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }
}

void _isolateMain(SendPort mainPort) {
  final exitCode = nativeMain();
  mainPort.send(exitCode);

  debugPrint('[ShallowBlue] nativeMain returns $exitCode');
}

void _isolateStdout(SendPort stdoutPort) {
  String previous = '';

  while (true) {
    final pointer = nativeStdoutRead();

    if (pointer.address == 0) {
      debugPrint('[ShallowBlue] nativeStdoutRead returns NULL');
      return;
    }

    final data = previous + pointer.toDartString();
    final lines = data.split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stdoutPort.send(line);
    }
  }
}

Future<bool> _spawnIsolates(List<SendPort> mainAndStdout) async {
  final initResult = nativeInit();
  if (initResult != 0) {
    debugPrint('[ShallowBlue] initResult=$initResult');
    return false;
  }

  try {
    await Isolate.spawn(_isolateStdout, mainAndStdout[1]);
  } catch (error) {
    debugPrint('[ShallowBlue] Failed to spawn stdout isolate: $error');
    return false;
  }

  try {
    await Isolate.spawn(_isolateMain, mainAndStdout[0]);
  } catch (error) {
    debugPrint('[ShallowBlue] Failed to spawn main isolate: $error');
    return false;
  }

  return true;
}
