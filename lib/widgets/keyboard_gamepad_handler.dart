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
