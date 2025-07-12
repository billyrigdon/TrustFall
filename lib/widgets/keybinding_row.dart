// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class KeyBindingRow extends StatefulWidget {
//   final String label;
//   final String action;
//   final String? currentBinding;
//   final void Function(String keyLabel) onBind;

//   const KeyBindingRow({
//     super.key,
//     required this.label,
//     required this.action,
//     required this.currentBinding,
//     required this.onBind,
//   });

//   @override
//   State<KeyBindingRow> createState() => _KeyBindingRowState();
// }

// class _KeyBindingRowState extends State<KeyBindingRow> {
//   bool listening = false;
//   FocusNode focusNode = FocusNode();

//   void _startListening() {
//     setState(() => listening = true);
//     focusNode.requestFocus();
//   }

//   void _onKey(RawKeyEvent event) {
//     if (listening && event is RawKeyDownEvent) {
//       final label =
//           event.logicalKey.keyLabel.isEmpty
//               ? event.logicalKey.debugName ?? 'Unknown'
//               : event.logicalKey.keyLabel;

//       widget.onBind(label);
//       setState(() => listening = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RawKeyboardListener(
//       focusNode: focusNode,
//       onKey: _onKey,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(widget.label, style: const TextStyle(color: Colors.white)),
//           TextButton(
//             onPressed: _startListening,
//             child: Text(
//               listening ? 'Press a key...' : widget.currentBinding ?? 'Unbound',
//               style: TextStyle(color: listening ? Colors.amber : Colors.cyan),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
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
  State<KeyBindingRow> createState() => _KeyBindingRowState();
}

class _KeyBindingRowState extends State<KeyBindingRow> {
  bool listening = false;
  FocusNode focusNode = FocusNode();

  StreamSubscription<GamepadEvent>? _gamepadSub;

  // void _startListening() {
  //   setState(() => listening = true);
  //   focusNode.requestFocus();

  //   _gamepadSub = Gamepads.events.listen((event) {
  //     if (!listening) return;

  //     if (event.type.toString().contains('axis') && event.value.abs() > 0.9) {
  //       final direction = event.value > 0 ? '+' : '-';
  //       final binding = '${event.gamepadId}:${event.key}:$direction';
  //       widget.onBind(binding);
  //       _stopListening(); // however you're ending the bind
  //     }

  //     if (event.type == KeyType.button && event.value == 1.0) {
  //       final binding = '${event.gamepadId}:${event.key}'; // ✅ NO :+ or :-
  //       widget.onBind(binding);
  //       _stopListening();
  //     }
  //   });
  // }

  void _startListening() {
    setState(() => listening = true);
    focusNode.requestFocus();

    _gamepadSub = Gamepads.events.listen((event) {
      if (!listening) return;
      print(event.type.toString());
      final isAxis =
          event.type.toString().contains('axis') ||
          event.type == KeyType.analog;
      final isButton = event.type == KeyType.button;
      final direction = event.value > 0 ? '+' : '-';

      final axisBinding = '${event.gamepadId}:${event.key}:$direction';
      final buttonBinding = '${event.gamepadId}:${event.key}';

      if (isAxis && event.value.abs() > 0.9) {
        // Only bind if direction matches expected one for this action
        final action = widget.action;
        final expected = {
          'MoveUp': '-',
          'MoveDown': '+',
          'MoveLeft': '-',
          'MoveRight': '+',
        };

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
          Text(widget.label, style: const TextStyle(color: Colors.white)),
          TextButton(
            onPressed: _startListening,
            child: Text(
              listening
                  ? 'Press a key or gamepad button...'
                  : widget.currentBinding ?? 'Unbound',
              style: TextStyle(color: listening ? Colors.amber : Colors.cyan),
            ),
          ),
        ],
      ),
    );
  }
}
