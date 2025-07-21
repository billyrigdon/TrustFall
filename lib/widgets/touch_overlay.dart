import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:game/services/settings_service.dart';

class TouchControls extends StatelessWidget {
  final void Function(String inputLabel, bool isPressed) onInput;

  const TouchControls({super.key, required this.onInput});

  Widget _styledButton(String label, String display) {
    return GestureDetector(
      onTapDown: (_) => onInput(label, true),
      onTapUp: (_) => onInput(label, false),
      onTapCancel: () => onInput(label, false),
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.9),
        ),
        child: Center(
          child: Text(
            display,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _hamburgerButton() {
    return GestureDetector(
      onTapDown: (_) => onInput('Key P', true),
      onTapUp: (_) => onInput('Key P', false),
      onTapCancel: () => onInput('Key P', false),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.9),
        ),
        child: const Center(
          child: Icon(Icons.menu, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useDpad = SettingsService().getUseDpad();

    return Stack(
      children: [
        Positioned(
          left: 80,
          bottom: 30,
          child: SizedBox(
            width: 150,
            height: 150,
            child:
                useDpad
                    ? DpadControls(onInput: onInput)
                    : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Joystick(
                        includeInitialAnimation: false,
                        mode: JoystickMode.all,
                        listener: (details) {
                          const threshold = 0.25;
                          onInput('Arrow Up', details.y < -threshold);
                          onInput('Arrow Down', details.y > threshold);
                          onInput('Arrow Left', details.x < -threshold);
                          onInput('Arrow Right', details.x > threshold);
                        },
                        base: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.7),
                              width: 2,
                            ),
                          ),
                        ),
                        stick: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
          ),
        ),

        Positioned(top: 16, right: 16, child: _hamburgerButton()),

        Positioned(right: 40, bottom: 80, child: _styledButton('Enter', 'A')),
        Positioned(
          right: 100,
          bottom: 40,
          child: _styledButton('Backspace', 'B'),
        ),
      ],
    );
  }
}

class DpadControls extends StatelessWidget {
  final void Function(String inputLabel, bool isPressed) onInput;

  const DpadControls({super.key, required this.onInput});

  Widget _dpadButton(String label, IconData icon) {
    return GestureDetector(
      onTapDown: (_) => onInput(label, true),
      onTapUp: (_) => onInput(label, false),
      onTapCancel: () => onInput(label, false),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.9),
        ),
        child: Icon(icon, size: 24, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dpadButton('Arrow Up', Icons.arrow_drop_up),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dpadButton('Arrow Left', Icons.arrow_left),
            const SizedBox(width: 40),
            _dpadButton('Arrow Right', Icons.arrow_right),
          ],
        ),
        _dpadButton('Arrow Down', Icons.arrow_drop_down),
      ],
    );
  }
}
