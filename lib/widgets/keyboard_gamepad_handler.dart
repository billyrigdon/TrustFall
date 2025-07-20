import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/services/settings_service.dart';
import 'package:gamepads/gamepads.dart';

enum GamepadInputMode { movement, menu }

class KeyboardGamepadListener extends StatefulWidget {
  final void Function(String inputLabel, bool isPressed) onInput;
  final GamepadInputMode inputMode;

  const KeyboardGamepadListener({
    super.key,
    required this.onInput,
    this.inputMode = GamepadInputMode.menu,
  });

  @override
  State<KeyboardGamepadListener> createState() =>
      KeyboardGamepadListenerState();
}

class KeyboardGamepadListenerState extends State<KeyboardGamepadListener> {
  final settings = SettingsService();
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<GamepadEvent>? _gamepadSub;
  Timer? _pollingTimer;
  final Set<String> _currentlyHeldInputs = {};
  final Map<String, DateTime> _inputHoldStart = {};
  final Map<String, DateTime> _lastRepeat = {};
  final Set<String> _firedOnce = {};

  Duration get initialDelay =>
      widget.inputMode == GamepadInputMode.menu
          ? Duration(milliseconds: 250)
          : Duration.zero;

  Duration get repeatInterval =>
      widget.inputMode == GamepadInputMode.menu
          ? Duration(milliseconds: 200)
          : Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_onKey);
    _gamepadSub = Gamepads.events.listen(_onGamepad);
    _startPolling();
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

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();

      // FIX: make a snapshot to avoid concurrent modification
      final heldSnapshot = _currentlyHeldInputs.toList();

      for (final input in heldSnapshot) {
        final start = _inputHoldStart[input] ?? now;
        final last =
            _lastRepeat[input] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final heldDuration = now.difference(start);
        final sinceLast = now.difference(last);

        // Fire immediately once
        if (!_firedOnce.contains(input)) {
          widget.onInput(input, true);
          _lastRepeat[input] = now;
          _firedOnce.add(input);
          continue;
        }

        // Wait for delay then repeat
        if (heldDuration >= initialDelay && sinceLast >= repeatInterval) {
          widget.onInput(input, true);
          _lastRepeat[input] = now;
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
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

    if (isPressed) {
      final wasHeld = _currentlyHeldInputs.contains(label);
      _currentlyHeldInputs.add(label);
      _inputHoldStart[label] ??= DateTime.now();
      if (!wasHeld) {
        _firedOnce.remove(label);
      }
    } else {
      _currentlyHeldInputs.remove(label);
      _inputHoldStart.remove(label);
      _lastRepeat.remove(label);
      _firedOnce.remove(label);
      widget.onInput(label, false);
    }
  }

  void _onGamepad(GamepadEvent event) {
    final typeStr = event.type.toString();
    final isAxis = typeStr.contains('axis') || typeStr.contains('analog');
    final isButton = event.type == KeyType.button;

    if (isAxis) {
      final axisPositive = '${event.gamepadId}:${event.key}:+';
      final axisNegative = '${event.gamepadId}:${event.key}:-';

      if (event.value >= 0.9) {
        _currentlyHeldInputs.add(axisPositive);
        _inputHoldStart[axisPositive] ??= DateTime.now();
        _firedOnce.remove(axisPositive);
      } else if (event.value <= -0.9) {
        _currentlyHeldInputs.add(axisNegative);
        _inputHoldStart[axisNegative] ??= DateTime.now();
        _firedOnce.remove(axisNegative);
      } else {
        for (final input in [axisPositive, axisNegative]) {
          _currentlyHeldInputs.remove(input);
          _inputHoldStart.remove(input);
          _lastRepeat.remove(input);
          _firedOnce.remove(input);
          widget.onInput(input, false);
        }
      }
    }

    if (isButton) {
      final input = '${event.gamepadId}:${event.key}';
      final isPressed = event.value == 1.0;

      widget.onInput(input, isPressed);
    }
  }

  void clearHeldInputs() {
    final heldCopy = Set<String>.from(_currentlyHeldInputs);
    for (final input in heldCopy) {
      widget.onInput(input, false); // safe now
    }

    _currentlyHeldInputs.clear();
    _inputHoldStart.clear();
    _lastRepeat.clear();
    _firedOnce.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _focusNode, child: const SizedBox.shrink());
  }
}
