// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:game/services/settings_service.dart';
// import 'package:gamepads/gamepads.dart';

// class KeyboardGamepadListener extends StatefulWidget {
//   final void Function(String inputLabel, bool isPressed) onInput;

//   const KeyboardGamepadListener({super.key, required this.onInput});

//   @override
//   State<KeyboardGamepadListener> createState() =>
//       KeyboardGamepadListenerState();
// }

// class KeyboardGamepadListenerState extends State<KeyboardGamepadListener> {
//   final settings = SettingsService();
//   StreamSubscription<GamepadEvent>? _gamepadSub;
//   final FocusNode _focusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     RawKeyboard.instance.addListener(_onKey);
//     _gamepadSub = Gamepads.events.listen(_onGamepad);

//     _requestFocus();
//   }

//   void regainFocus() => _requestFocus();

//   @override
//   void dispose() {
//     _gamepadSub?.cancel();
//     RawKeyboard.instance.removeListener(_onKey);
//     _focusNode.dispose();
//     super.dispose();
//   }

//   void _requestFocus() {
//     print('regain');
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted && !_focusNode.hasFocus) {
//         _focusNode.requestFocus();
//       }
//     });
//   }

//   void _onKey(RawKeyEvent event) {
//     print('onkey');
//     if (event is! RawKeyDownEvent) return;

//     final keyLabel =
//         event.logicalKey.keyLabel.isEmpty
//             ? event.logicalKey.debugName ?? ''
//             : event.logicalKey.keyLabel;

//     widget.onInput(keyLabel, true);
//   }

//   void _onGamepad(GamepadEvent event) {
//     final typeString = event.type.toString();
//     final isAxis = typeString.contains('axis') || typeString.contains('analog');
//     final input =
//         isAxis
//             ? '${event.gamepadId}:${event.key}:${event.value > 0 ? '+' : '-'}'
//             : '${event.gamepadId}:${event.key}';

//     final up = settings.getBinding('MoveUp');
//     final down = settings.getBinding('MoveDown');
//     final left = settings.getBinding('MoveLeft');
//     final right = settings.getBinding('MoveRight');
//     final action = settings.getBinding('Action');

//     if (isAxis && event.value.abs() > 0.9) {
//       if (input == up) widget.onInput(up, true);
//       if (input == down) widget.onInput(down, true);
//       if (input == left) widget.onInput(left, true);
//       if (input == right) widget.onInput(right, true);
//     }

//     if (event.type == KeyType.button && event.value == 1.0) {
//       if (input == action) widget.onInput(action, true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Focus(
//       focusNode: _focusNode,
//       child: const SizedBox.shrink(),
//     ); // Invisible
//   }
// }
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/services/settings_service.dart';
import 'package:gamepads/gamepads.dart';

class KeyboardGamepadListener extends StatefulWidget {
  final void Function(String inputLabel, bool isPressed) onInput;

  const KeyboardGamepadListener({super.key, required this.onInput});

  @override
  State<KeyboardGamepadListener> createState() =>
      KeyboardGamepadListenerState();
}

class KeyboardGamepadListenerState extends State<KeyboardGamepadListener> {
  final settings = SettingsService();
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<GamepadEvent>? _gamepadSub;

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_onKey);
    _gamepadSub = Gamepads.events.listen(_onGamepad);
    _requestFocus();
  }

  void regainFocus() => _requestFocus();

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_onKey);
    _gamepadSub?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(RawKeyEvent event) {
    final key = event.logicalKey;
    final label = key.keyLabel.isEmpty ? key.debugName ?? '' : key.keyLabel;

    


    if (label.isEmpty) return;

    final isPressed = event is RawKeyDownEvent;
    widget.onInput(label, isPressed);
  }

  void _onGamepad(GamepadEvent event) {
    final typeStr = event.type.toString();
    final isAxis = typeStr.contains('axis') || typeStr.contains('analog');
    final isButton = event.type == KeyType.button;

    if (isAxis) {
      final axisPositive = '${event.gamepadId}:${event.key}:+';
      final axisNegative = '${event.gamepadId}:${event.key}:-';

      if (event.value >= 0.9) {
        widget.onInput(axisPositive, true);
        widget.onInput(axisNegative, false); // cancel opposite
      } else if (event.value <= -0.9) {
        widget.onInput(axisNegative, true);
        widget.onInput(axisPositive, false);
      } else {
        widget.onInput(axisPositive, false);
        widget.onInput(axisNegative, false);
      }
    }

    if (isButton) {
      final input = '${event.gamepadId}:${event.key}';
      final isPressed = event.value == 1.0;
      widget.onInput(input, isPressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _focusNode, child: const SizedBox.shrink());
  }
}
