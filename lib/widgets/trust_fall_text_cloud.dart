import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';

class TrustFallTextCloud extends StatefulWidget {
  final TrustFall game;
  const TrustFallTextCloud({super.key, required this.game});

  @override
  TrustFallTextCloudState createState() => TrustFallTextCloudState();
}

class TrustFallTextCloudState extends State<TrustFallTextCloud> {
  List<String> lines = [];
  List<String> choices = [];
  void Function(String choice)? onChoiceSelected;
  int currentLine = 0;
  int selectedChoiceIndex = 0;
  VoidCallback? onComplete;
  Vector2? bubblePosition;

  void startDialogue(
    List<String> newLines, {
    List<String>? choices,
    void Function(String choice)? onChoiceSelected,
    VoidCallback? onComplete,
    Vector2? worldPosition,
  }) {
    setState(() {
      lines = newLines;
      this.choices = choices ?? [];
      this.onChoiceSelected = onChoiceSelected;
      this.onComplete = onComplete;
      currentLine = 0;
      selectedChoiceIndex = 0;
      bubblePosition =
          worldPosition != null
              ? widget.game.worldToScreen(worldPosition)
              : null;
    });
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
      bubblePosition = null;
    });

    widget.game.overlays.remove('TextBox');
  }

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

  Widget _buildSpeechBubble(Vector2 position) {
    const bubbleWidth = 150.0;
    const borderRadius = 24.0;
    return Positioned(
      left: position.x - bubbleWidth / 2,
      top: position.y - 160,
      child: Column(
        children: [
          SizedBox(
            width: bubbleWidth,
            height: bubbleWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      lines[currentLine],
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Ithica',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 95.0),
            child: ClipPath(
              clipper: TriangleClipper(),
              child: Container(color: Colors.white, width: 20, height: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredBox(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 0.5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.9)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (choices.isEmpty)
                Text(
                  lines[currentLine],
                  style: TextStyle(
                    fontFamily: 'Ithica',
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 12),
              if (choices.isNotEmpty && currentLine == lines.length - 1)
                ...List.generate(choices.length, (index) {
                  final isSelected = index == selectedChoiceIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextButton(
                      onPressed: () {
                        onChoiceSelected?.call(choices[index]);
                        _close();
                      },
                      child: Text(
                        choices[index],
                        style: TextStyle(
                          fontFamily: 'Ithica',
                          fontSize: 20,
                          color: Colors.white,
                          decoration:
                              isSelected
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                        ),
                      ),
                    ),
                  );
                }),
              if (choices.isEmpty || currentLine < lines.length - 1)
                TextButton(
                  onPressed: _next,
                  child: const Text(
                    '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Ithica',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    final isFinalLine = currentLine == lines.length - 1;
    final shouldShowChoices = isFinalLine && choices.isNotEmpty;

    if (shouldShowChoices) {
      return Stack(
        children: [
          _buildCenteredBox(context),
          if (bubblePosition != null) _buildSpeechBubble(bubblePosition!),
        ],
      );
    } else if (bubblePosition != null) {
      return _buildSpeechBubble(bubblePosition!);
    } else {
      return _buildCenteredBox(context); // fallback if no position
    }
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
