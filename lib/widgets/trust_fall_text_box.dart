import 'package:flutter/material.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';

class TrustFallTextBox extends StatefulWidget {
  TrustFall game;
  TrustFallTextBox({super.key, required this.game});

  @override
  TrustFallTextBoxState createState() => TrustFallTextBoxState();
}

class TrustFallTextBoxState extends State<TrustFallTextBox> {
  List<String> lines = [];
  List<String> choices = [];
  void Function(String choice)? onChoiceSelected;
  int currentLine = 0;
  int selectedChoiceIndex = 0;
  VoidCallback? onComplete;

  void startDialogue(
    List<String> newLines, {
    List<String>? choices,
    void Function(String choice)? onChoiceSelected,
    VoidCallback? onComplete,
  }) {
    setState(() {
      lines = newLines;
      this.choices = choices ?? [];
      this.onChoiceSelected = onChoiceSelected;
      this.onComplete = onComplete;
      currentLine = 0;
      selectedChoiceIndex = 0;
    });

    // if (autoAdvance) {
    //   // Wait just a moment, then close the dialogue and trigger onComplete
    //   Future.delayed(const Duration(milliseconds: 1500), () {
    //     if (mounted) _close();
    //   });
    // }
  }

  void _next() {
    if (currentLine < lines.length - 1) {
      setState(() => currentLine++);
    } else if (choices.isEmpty) {
      _close();
    }
  }

  void _close() {
    onComplete?.call();
    setState(() {
      lines = [];
      choices = [];
      onChoiceSelected = null;
      onComplete = null;
      selectedChoiceIndex = 0;
    });

    widget.game.overlays.remove('TextBox');
  }

  /// 🎮 Handles input from KeyboardGamepadListener
  void handleInput(String inputLabel) {
    final settings = SettingsService();
    final up = settings.getBinding('MoveUp');
    final down = settings.getBinding('MoveDown');
    final action = settings.getBinding('Action');

    final isUp =
        inputLabel == up || inputLabel == 'Arrow Up' || inputLabel == 'W';
    final isDown =
        inputLabel == down || inputLabel == 'Arrow Down' || inputLabel == 'S';
    final isAction =
        inputLabel == action ||
        inputLabel == 'Enter' ||
        inputLabel == 'Z' ||
        inputLabel == ' ' ||
        inputLabel == 'Space';

    if (choices.isNotEmpty && currentLine == lines.length - 1) {
      if (isUp) {
        setState(() {
          selectedChoiceIndex =
              (selectedChoiceIndex - 1 + choices.length) % choices.length;
        });
      } else if (isDown) {
        setState(() {
          selectedChoiceIndex = (selectedChoiceIndex + 1) % choices.length;
        });
      } else if (isAction) {
        final choice = choices[selectedChoiceIndex];
        onChoiceSelected?.call(choice);
        _close();
      }
    } else if (isAction) {
      _next();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 0.6,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lines[currentLine],
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (choices.isNotEmpty && currentLine == lines.length - 1)
                ...List.generate(choices.length, (index) {
                  final isSelected = index == selectedChoiceIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSelected ? Colors.white : Colors.grey[800],
                        foregroundColor:
                            isSelected ? Colors.black : Colors.white,
                      ),
                      onPressed: () {
                        onChoiceSelected?.call(choices[index]);
                        _close();
                      },
                      child: Text(choices[index]),
                    ),
                  );
                }),
              if (choices.isEmpty || currentLine < lines.length - 1)
                TextButton(
                  onPressed: _next,
                  child: const Text(
                    'Next',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
