// import 'package:flame/game.dart';
// import 'package:flutter/material.dart';
// import 'package:game/main.dart';
// import 'package:game/services/settings_service.dart';

// class TrustFallTextCloud extends StatefulWidget {
//   final TrustFall game;
//   const TrustFallTextCloud({super.key, required this.game});

//   @override
//   TrustFallTextCloudState createState() => TrustFallTextCloudState();
// }

// class TrustFallTextCloudState extends State<TrustFallTextCloud> {
//   List<String> lines = [];
//   List<String> choices = [];
//   void Function(String choice)? onChoiceSelected;
//   int currentLine = 0;
//   int selectedChoiceIndex = 0;
//   VoidCallback? onComplete;
//   Vector2? bubblePosition;

//   void startDialogue(
//     List<String> newLines, {
//     List<String>? choices,
//     void Function(String choice)? onChoiceSelected,
//     VoidCallback? onComplete,
//     Vector2? worldPosition,
//   }) {
//     setState(() {
//       lines = newLines;
//       this.choices = choices ?? [];
//       this.onChoiceSelected = onChoiceSelected;
//       this.onComplete = onComplete;
//       currentLine = 0;
//       selectedChoiceIndex = 0;
//       bubblePosition =
//           worldPosition != null
//               ? widget.game.worldToScreen(worldPosition)
//               : null;
//     });
//   }

//   void _next() {
//     if (currentLine < lines.length - 1) {
//       setState(() => currentLine++);
//     } else if (choices.isEmpty) {
//       _close();
//     }
//   }

//   void _close() {
//     onComplete?.call();
//     setState(() {
//       lines = [];
//       choices = [];
//       onChoiceSelected = null;
//       onComplete = null;
//       selectedChoiceIndex = 0;
//     });

//     widget.game.overlays.remove('TextBox');
//   }

//   /// 🎮 Handles input from KeyboardGamepadListener
//   void handleInput(String inputLabel) {
//     final settings = SettingsService();
//     final up = settings.getBinding('MoveUp');
//     final down = settings.getBinding('MoveDown');
//     final action = settings.getBinding('Action');

//     final isUp =
//         inputLabel == up || inputLabel == 'Arrow Up' || inputLabel == 'W';
//     final isDown =
//         inputLabel == down || inputLabel == 'Arrow Down' || inputLabel == 'S';
//     final isAction =
//         inputLabel == action ||
//         inputLabel == 'Enter' ||
//         inputLabel == 'Z' ||
//         inputLabel == ' ' ||
//         inputLabel == 'Space';

//     if (choices.isNotEmpty && currentLine == lines.length - 1) {
//       if (isUp) {
//         setState(() {
//           selectedChoiceIndex =
//               (selectedChoiceIndex - 1 + choices.length) % choices.length;
//         });
//       } else if (isDown) {
//         setState(() {
//           selectedChoiceIndex = (selectedChoiceIndex + 1) % choices.length;
//         });
//       } else if (isAction) {
//         final choice = choices[selectedChoiceIndex];
//         onChoiceSelected?.call(choice);
//         _close();
//       }
//     } else if (isAction) {
//       _next();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (lines.isEmpty) return const SizedBox.shrink();

//     final screenPos = bubblePosition ?? Vector2(200, 200);
//     const bubbleWidth = 250.0;

//     return Positioned(
//       left: screenPos.x - (bubbleWidth / 2),
//       top: screenPos.y - 80,
//       width: bubbleWidth,
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.85),
//           border: Border.all(color: Colors.white),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               lines[currentLine],
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontFamily: 'Ithica',
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             if (choices.isNotEmpty && currentLine == lines.length - 1)
//               ...List.generate(choices.length, (index) {
//                 final isSelected = index == selectedChoiceIndex;
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4),
//                   child: TextButton(
//                     onPressed: () {
//                       onChoiceSelected?.call(choices[index]);
//                       _close();
//                     },
//                     child: Text(
//                       choices[index],
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         decoration:
//                             isSelected
//                                 ? TextDecoration.underline
//                                 : TextDecoration.none,
//                       ),
//                     ),
//                   ),
//                 );
//               }),
//             if (choices.isEmpty || currentLine < lines.length - 1)
//               TextButton(
//                 onPressed: _next,
//                 child: const Text(
//                   'Next',
//                   style: TextStyle(color: Colors.white70, fontFamily: 'Ithica'),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';
// import 'package:vector_math/vector_math_64.dart';

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

  Widget _buildSpeechBubble(Vector2 position) {
    const bubbleWidth = 150.0;
    const borderRadius = 24.0;
    // final triangleOffset = position.x - bubbleLeft - 10;
    return Positioned(
      left: position.x - bubbleWidth / 2,
      top: position.y - 160,
      // width: bubbleWidth,
      // height: bubbleWidth,
      child: Column(
        children: [
          // Bubble with fixed width
          SizedBox(
            width: bubbleWidth,
            height: bubbleWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                // border: Border.all(color: Colors.black),
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

          // Triangle tail
          // const SizedBox(height: 2),
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

  // Widget _buildSpeechBubble(Vector2 position) {
  //   const bubbleWidth = 250.0;

  //   return Positioned(
  //     left: position.x - bubbleWidth / 2,
  //     top: position.y - 100,
  //     width: bubbleWidth,
  //     child: Column(
  //       children: [
  //         // Main bubble
  //         Container(
  //           width: 72,
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             border: Border.all(color: Colors.white),
  //             borderRadius: BorderRadius.circular(16),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 lines[currentLine],
  //                 style: const TextStyle(
  //                   color: Colors.black,
  //                   fontSize: 20,
  //                   fontFamily: 'Ithica',
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: 12),
  //               if (choices.isEmpty || currentLine < lines.length - 1)
  //                 TextButton(
  //                   onPressed: _next,
  //                   child: const Text(
  //                     'Next',
  //                     style: TextStyle(
  //                       color: Colors.black,
  //                       fontFamily: 'Ithica',
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //         ),

  //         // Triangle Tail
  //         const SizedBox(height: 2),
  //         ClipPath(
  //           clipper: TriangleClipper(),
  //           child: Container(color: Colors.white, width: 20, height: 10),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildCenteredBox(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 0.5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            // borderRadius: BorderRadius.circular(12),
            // border: Border.all(color: Colors.white),
          ),
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

  // @override
  // Widget build(BuildContext context) {
  //   if (lines.isEmpty) return const SizedBox.shrink();

  //   if (bubblePosition != null) {
  //     return _buildSpeechBubble(bubblePosition!);
  //   } else {
  //     return _buildCenteredBox(context);
  //   }
  // }
}

// 👇 Draws the speech bubble tail
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
