import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/features/battle/battle_manager.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/health_bar.dart';
import 'package:gamepads/gamepads.dart';

class BattleOverlay extends StatefulWidget {
  final TrustFall game;
  const BattleOverlay({super.key, required this.game});

  @override
  State<BattleOverlay> createState() => _BattleOverlayState();
}

// class _BattleOverlayState extends State<BattleOverlay> {
//   final BattleManager battleManager = BattleManager();
//   int selectedIndex = 0;
//   bool itemMenuOpen = false;

//   final List<String> commands = ['Attack', 'Items', 'Run'];
//   final List<String> items = ['Burger', 'Cola'];

//   @override
//   void initState() {
//     super.initState();
//     battleManager.reset();
//     RawKeyboard.instance.addListener(_onKey);
//   }

//   @override
//   void dispose() {
//     RawKeyboard.instance.removeListener(_onKey);
//     super.dispose();
//   }

//   void _onKey(RawKeyEvent event) {
//     if (!battleManager.playerTurn || battleManager.battleEnded) return;

//     if (event is RawKeyDownEvent) {
//       final key = event.logicalKey;
//       final rowCount = itemMenuOpen ? items.length : 2;

//       if (key == LogicalKeyboardKey.arrowRight && !itemMenuOpen) {
//         setState(() => selectedIndex = (selectedIndex + 1) % commands.length);
//       } else if (key == LogicalKeyboardKey.arrowLeft && !itemMenuOpen) {
//         setState(
//           () =>
//               selectedIndex =
//                   (selectedIndex - 1 + commands.length) % commands.length,
//         );
//       } else if (key == LogicalKeyboardKey.arrowDown && itemMenuOpen) {
//         setState(() => selectedIndex = (selectedIndex + 1) % items.length);
//       } else if (key == LogicalKeyboardKey.arrowUp && itemMenuOpen) {
//         setState(
//           () =>
//               selectedIndex = (selectedIndex - 1 + items.length) % items.length,
//         );
//       } else if (key == LogicalKeyboardKey.enter ||
//           key == LogicalKeyboardKey.space) {
//         _handleSelection();
//       }
//     }
//   }

//   void _handleSelection() {
//     if (itemMenuOpen) {
//       battleManager.useItem(items[selectedIndex]);
//       setState(() {
//         itemMenuOpen = false;
//         selectedIndex = 0;
//       });
//     } else {
//       switch (commands[selectedIndex]) {
//         case 'Attack':
//           battleManager.attackEnemy();
//           break;
//         case 'Items':
//           setState(() {
//             itemMenuOpen = true;
//             selectedIndex = 0;
//           });
//           break;
//         case 'Run':
//           battleManager.battleEnded = true;
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (mounted) widget.game.endBattle();
//           });
//           break;
//       }
//     }
//   }

// }

class _BattleOverlayState extends State<BattleOverlay> {
  final BattleManager battleManager = BattleManager();
  int selectedIndex = 0;
  bool itemMenuOpen = false;

  final List<String> commands = ['Attack', 'Items', 'Run'];
  final List<String> items = ['Burger', 'Cola'];

  StreamSubscription<GamepadEvent>? _gamepadSub;
  final SettingsService settings = SettingsService();

  @override
  void initState() {
    super.initState();
    battleManager.reset();
    RawKeyboard.instance.addListener(_onKey);
    _gamepadSub = Gamepads.events.listen(_onGamepad);
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_onKey);
    _gamepadSub?.cancel();
    super.dispose();
  }

  void _onKey(RawKeyEvent event) {
    if (!battleManager.playerTurn || battleManager.battleEnded) return;
    if (event is! RawKeyDownEvent) return;

    final label =
        event.logicalKey.keyLabel.isNotEmpty
            ? event.logicalKey.keyLabel
            : event.logicalKey.debugName ?? '';

    _handleInput(label);
  }

  void _onGamepad(GamepadEvent event) {
    if (!battleManager.playerTurn || battleManager.battleEnded) return;

    final typeStr = event.type.toString();
    final isAxis = typeStr.contains('axis') || event.type == KeyType.analog;
    final isButton = event.type == KeyType.button;

    if (isAxis && event.value.abs() > 0.9) {
      final dir = event.value > 0 ? '+' : '-';
      final input = '${event.gamepadId}:${event.key}:$dir';
      _handleInput(input);
    }

    if (isButton && event.value == 1.0) {
      final input = '${event.gamepadId}:${event.key}';
      _handleInput(input);
    }
  }

  void _handleInput(String inputLabel) {
    final up = settings.getBinding('MoveUp');
    final down = settings.getBinding('MoveDown');
    final left = settings.getBinding('MoveLeft');
    final right = settings.getBinding('MoveRight');
    final action = settings.getBinding('Action');

    final isRight = inputLabel == right || inputLabel == 'Arrow Right';
    final isLeft = inputLabel == left || inputLabel == 'Arrow Left';
    final isDown = inputLabel == down || inputLabel == 'Arrow Down';
    final isUp = inputLabel == up || inputLabel == 'Arrow Up';
    final isAction =
        inputLabel == action || inputLabel == 'Enter' || inputLabel == 'Space';

    if (isRight && !itemMenuOpen) {
      setState(() => selectedIndex = (selectedIndex + 1) % commands.length);
    } else if (isLeft && !itemMenuOpen) {
      setState(
        () =>
            selectedIndex =
                (selectedIndex - 1 + commands.length) % commands.length,
      );
    } else if (isDown && itemMenuOpen) {
      setState(() => selectedIndex = (selectedIndex + 1) % items.length);
    } else if (isUp && itemMenuOpen) {
      setState(
        () => selectedIndex = (selectedIndex - 1 + items.length) % items.length,
      );
    } else if (isAction) {
      _handleSelection();
    }
  }

  void _handleSelection() {
    if (itemMenuOpen) {
      battleManager.useItem(items[selectedIndex]);
      setState(() {
        itemMenuOpen = false;
        selectedIndex = 0;
      });
    } else {
      switch (commands[selectedIndex]) {
        case 'Attack':
          battleManager.attackEnemy();
          break;
        case 'Items':
          setState(() {
            itemMenuOpen = true;
            selectedIndex = 0;
          });
          break;
        case 'Run':
          battleManager.battleEnded = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.game.endBattle();
          });
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: AnimatedBuilder(
          animation: battleManager,
          builder: (_, __) {
            if (battleManager.battleEnded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.game.endBattle();
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '''
     /\\___/\\
    ( o   o )
    (  =^=  )
    (        )
    (         )
    (          ))))))))''',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                HealthBar(label: 'Enemy HP', hp: battleManager.enemyHP),
                const SizedBox(height: 16),
                HealthBar(label: 'Your HP', hp: battleManager.playerHP),
                const SizedBox(height: 24),
                if (battleManager.battleEnded)
                  Text(
                    battleManager.playerHP == 0 ? 'You lost!' : 'You won!',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  )
                else if (!battleManager.playerTurn)
                  const Text(
                    "Enemy is attacking...",
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(8),
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        itemMenuOpen
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(items.length, (i) {
                                final selected = i == selectedIndex;
                                return Text(
                                  '${selected ? '▶' : '  '} ${items[i]}',
                                  style: TextStyle(
                                    color:
                                        selected ? Colors.amber : Colors.white,
                                    fontWeight:
                                        selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                );
                              }),
                            )
                            : GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: 2,
                              childAspectRatio: 3.5,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              children: List.generate(commands.length, (i) {
                                final selected = i == selectedIndex;
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          selected
                                              ? Colors.amber
                                              : Colors.white,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.black,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Center(
                                    child: Text(
                                      commands[i],
                                      style: TextStyle(
                                        color:
                                            selected
                                                ? Colors.amber
                                                : Colors.white,
                                        fontWeight:
                                            selected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
