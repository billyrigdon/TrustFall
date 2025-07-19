import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';

class KeyBindingRow extends StatefulWidget {
  final String label;
  final String action;
  final String? currentBinding;
  final void Function(String keyLabel) onBind;

  const KeyBindingRow({
    super.key,
    required this.label,
    required this.action,
    required this.currentBinding,
    required this.onBind,
  });

  @override
  State<KeyBindingRow> createState() => KeyBindingRowState();
}

class KeyBindingRowState extends State<KeyBindingRow> {
  bool listening = false;
  final FocusNode focusNode = FocusNode();

  StreamSubscription<GamepadEvent>? _gamepadSub;

  void startListeningExternally() {
    if (!listening) _startListening();
  }

  void _startListening() {
    setState(() => listening = true);
    focusNode.requestFocus();

    _gamepadSub = Gamepads.events.listen((event) {
      if (!listening) return;
      final isAxis =
          event.type.toString().contains('axis') ||
          event.type == KeyType.analog;
      final isButton = event.type == KeyType.button;
      final direction = event.value > 0 ? '+' : '-';

      final axisBinding = '${event.gamepadId}:${event.key}:$direction';
      final buttonBinding = '${event.gamepadId}:${event.key}';

      final action = widget.action;
      final expected = {
        'MoveUp': '-',
        'MoveDown': '+',
        'MoveLeft': '-',
        'MoveRight': '+',
      };

      if (isAxis && event.value.abs() > 0.9) {
        if (expected.containsKey(action) && expected[action] == direction) {
          widget.onBind(axisBinding);
          _stopListening();
        }
      }

      if (isButton && event.value == 1.0) {
        widget.onBind(buttonBinding);
        _stopListening();
      }
    });
  }

  void _stopListening() {
    _gamepadSub?.cancel();
    setState(() => listening = false);
  }

  void _onKey(RawKeyEvent event) {
    if (!listening || event is! RawKeyDownEvent) return;

    final label =
        event.logicalKey.keyLabel.isEmpty
            ? event.logicalKey.debugName ?? 'Unknown'
            : event.logicalKey.keyLabel;

    widget.onBind(label);
    _stopListening();
  }

  @override
  void dispose() {
    _gamepadSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: _onKey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Ithica',
              fontSize: 24,
            ),
          ),
          TextButton(
            onPressed: _startListening,
            child: Text(
              listening
                  ? 'Press a key or gamepad button...'
                  : widget.currentBinding ?? 'Unbound',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Ithica',
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
