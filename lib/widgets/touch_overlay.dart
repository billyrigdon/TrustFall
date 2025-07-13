// touch_controls.dart
import 'package:flutter/material.dart';

class StartControls extends StatelessWidget {
  final void Function(String inputLabel) onInput;

  const StartControls({super.key, required this.onInput});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Row(
        children: [
          // Left D-pad
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _controlButton('Arrow Up', onInput),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _controlButton('Arrow Left', onInput),
                      const SizedBox(width: 48), // spacer
                      _controlButton('Arrow Right', onInput),
                    ],
                  ),
                  _controlButton('Arrow Down', onInput),
                ],
              ),
            ),
          ),
          // Right Buttons
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _controlButton('Enter', onInput, label: 'A'),
                  const SizedBox(height: 16),
                  _controlButton('Space', onInput, label: 'B'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(
    String inputLabel,
    void Function(String) onInput, {
    String? label,
  }) {
    return GestureDetector(
      onTap: () => onInput(inputLabel),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: Text(
          label ?? inputLabel,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class TouchControls extends StatelessWidget {
  final void Function(String inputLabel, bool isPressed) onInput;

  const TouchControls({super.key, required this.onInput});

  Widget _button(String label, IconData icon, {double size = 48}) {
    return GestureDetector(
      onTapDown: (_) => onInput(label, true),
      onTapUp: (_) => onInput(label, false),
      onTapCancel: () => onInput(label, false),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _labeledButton(String label, String display) {
    return GestureDetector(
      onTapDown: (_) => onInput(label, true),
      onTapUp: (_) => onInput(label, false),
      onTapCancel: () => onInput(label, false),
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.amber.withOpacity(0.85),
        ),
        child: Center(
          child: Text(
            display,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // D-Pad (Bottom Left)
        Positioned(
          left: 20,
          bottom: 20,
          child: Column(
            children: [
              _button('Arrow Up', Icons.arrow_drop_up),
              Row(
                children: [
                  _button('Arrow Left', Icons.arrow_left),
                  const SizedBox(width: 48),
                  _button('Arrow Right', Icons.arrow_right),
                ],
              ),
              _button('Arrow Down', Icons.arrow_drop_down),
            ],
          ),
        ),

        // Action + Pause (Bottom Right)
        Positioned(
          right: 20,
          bottom: 40,
          child: Column(
            children: [
              _labeledButton('Key P', '⏸'), // Pause
              const SizedBox(height: 12),
              _labeledButton('Enter', 'A'), // Action
            ],
          ),
        ),
      ],
    );
  }
}
