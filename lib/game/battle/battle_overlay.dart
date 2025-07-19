import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game/game/battle/battle_manager.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/game/characters/enemies/enemy.dart' as game_enemy;
import 'package:game/game/characters/main_player.dart';
import 'package:game/models/items.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/health_bar.dart';

class BattleOverlay extends StatefulWidget {
  final TrustFall game;
  final List<BattleCharacter> party;
  final game_enemy.Enemy enemy;

  const BattleOverlay({
    super.key,
    required this.game,
    required this.party,
    required this.enemy,
  });

  @override
  State<BattleOverlay> createState() => BattleOverlayState();
}

class BattleOverlayState extends State<BattleOverlay> {
  late final BattleManager battleManager;
  int selectedIndex = 0;
  bool itemMenuOpen = false;
  bool attackMenuOpen = false;
  int attackIndex = 0;
  int turnIndex = 0;
  final SettingsService settings = SettingsService();
  List<String> queuedMessages = [];

  String? modalMessage;
  Completer<void>? _modalCompleter;

  List<String> commands = ['Attack', 'Run'];

  // List<Item> get mainInventory {
  //   final main = battleManager.party.firstWhere((c) => c is MainPlayer);
  //   return main.inventory;
  // }

  List<Item> get mainInventory {
    final main = battleManager.party.firstWhere((c) => c is MainPlayer);
    return main.inventory
        .where((item) => item.type != ItemType.currency)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    battleManager = BattleManager(party: widget.party, enemy: widget.enemy);
    if (mainInventory.isNotEmpty) {
      commands = ['Attack', 'Items', 'Run'];
    }
    battleManager.reset();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> showMessage(
    String message, {
    bool requireConfirmation = false,
  }) async {
    setState(() {
      attackMenuOpen = false;
      modalMessage = message;
    });

    _modalCompleter = Completer<void>();

    if (!requireConfirmation) {
      // Prevent early dismissal
      await Future.delayed(const Duration(seconds: 2));
      if (_modalCompleter != null && !_modalCompleter!.isCompleted) {
        setState(() => modalMessage = null);
        _modalCompleter!.complete();
      }
    } else {
      await Future.delayed(const Duration(seconds: 4));
      if (_modalCompleter != null && !_modalCompleter!.isCompleted) {
        setState(() => modalMessage = null);
        _modalCompleter!.complete();
      }
    }

    return;
  }

  // Future<void> showMessage(
  //   String message, {
  //   bool requireConfirmation = false,
  // }) async {
  //   setState(() {
  //     attackMenuOpen = false;
  //   });

  //   _modalCompleter = Completer<void>();

  //   setState(() {
  //     modalMessage = message;
  //   });

  //   if (!requireConfirmation) {
  //     // auto-complete after delay
  //     Future.delayed(const Duration(seconds: 2), () {
  //       if (_modalCompleter != null && !_modalCompleter!.isCompleted) {
  //         setState(() => modalMessage = null);
  //         _modalCompleter!.complete();
  //       }
  //     });
  //   }

  //   return _modalCompleter!.future;
  // }

  final ScrollController _scrollController = ScrollController();

  void _scrollToSelectedItem(int index) {
    const itemWidth = 120.0; // adjust if needed
    _scrollController.animateTo(
      index * itemWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void handleInput(String inputLabel) {
    if (modalMessage != null) {
      return;
    }
    final up = settings.getBinding('MoveUp');
    final down = settings.getBinding('MoveDown');
    final left = settings.getBinding('MoveLeft');
    final right = settings.getBinding('MoveRight');
    final action = settings.getBinding('Action');
    final back = settings.getBinding('Back');
    final isRight = inputLabel == right || inputLabel == 'Arrow Right';
    final isLeft = inputLabel == left || inputLabel == 'Arrow Left';
    final isDown = inputLabel == down || inputLabel == 'Arrow Down';
    final isUp = inputLabel == up || inputLabel == 'Arrow Up';
    final isAction =
        inputLabel == action || inputLabel == 'Enter' || inputLabel == 'Space';

    final isBack = inputLabel == back || inputLabel == 'Backspace';

    // if (modalMessage != null) {
    //   if (isAction &&
    //       _modalCompleter != null &&
    //       !_modalCompleter!.isCompleted) {
    //     setState(() => modalMessage = null);
    //     _modalCompleter!.complete();
    //   }
    //   return;
    // }

    if (isBack) {
      if (itemMenuOpen || attackMenuOpen) {
        setState(() {
          itemMenuOpen = false;
          attackMenuOpen = false;
          selectedIndex = 0;
          attackIndex = 0;
        });
        return;
      }
    }

    if (isRight && !itemMenuOpen && !attackMenuOpen) {
      setState(() => selectedIndex = (selectedIndex + 1) % commands.length);
    } else if (isLeft && !itemMenuOpen && !attackMenuOpen) {
      setState(
        () =>
            selectedIndex =
                (selectedIndex - 1 + commands.length) % commands.length,
      );
    } else if (isRight && itemMenuOpen) {
      setState(() {
        selectedIndex = (selectedIndex + 1) % mainInventory.length;
        _scrollToSelectedItem(selectedIndex);
      });
    } else if (isLeft && itemMenuOpen) {
      setState(() {
        selectedIndex =
            (selectedIndex - 1 + mainInventory.length) % mainInventory.length;
        _scrollToSelectedItem(selectedIndex);
      });
    } else if (isRight && attackMenuOpen) {
      final currentChar = battleManager.party[turnIndex];

      setState(
        () => attackIndex = (attackIndex + 1) % currentChar.attacks.length,
      );
    } else if (isLeft && attackMenuOpen) {
      final currentChar = battleManager.party[turnIndex];

      setState(
        () =>
            attackIndex =
                (attackIndex - 1 + currentChar.attacks.length) %
                currentChar.attacks.length,
      );
    } else if (isAction) {
      // if (modalMessage == null) {
      _handleSelection();
      // }
    }
  }

  void _handleSelection() async {
    final currentChar = battleManager.party[turnIndex];

    if (itemMenuOpen) {
      final item = mainInventory[selectedIndex];

      await battleManager.useItemOn(currentChar, item, showMessage);

      setState(() {
        itemMenuOpen = false;
        selectedIndex = 0;
        if (mainInventory.isEmpty) {
          commands = ['Attack', 'Run'];
        }
      });

      await _endTurn();
    } else if (attackMenuOpen) {
      final attack = currentChar.attacks[attackIndex];
      await battleManager.attackEnemy(currentChar, attack, showMessage);

      setState(() {
        attackMenuOpen = false;
        attackIndex = 0;
      });

      await _endTurn();
    } else {
      switch (commands[selectedIndex]) {
        case 'Attack':
          setState(() {
            attackMenuOpen = true;
            attackIndex = 0;
          });
          break;
        case 'Items':
          setState(() {
            itemMenuOpen = true;
            selectedIndex = 0;
          });
          break;
        case 'Run':
          setState(() {
            attackMenuOpen = false;
            itemMenuOpen = false;
            selectedIndex = 0;
          });

          await showMessage(
            '${currentChar.name} ran away!',
            requireConfirmation: true,
          );
          battleManager.battleEnded = true;

          if (mounted)
            widget.game
                .endBattle(); // optional: delay this if you want confirmation
          return; // ✅ Early return to prevent continuing
      }
    }
  }

  Future<void> _endTurn() async {
    turnIndex++;
    if (turnIndex >= battleManager.party.length) {
      turnIndex = 0;
      battleManager.playerTurn = false;

      if (battleManager.battleEnded) {
        if (mounted) widget.game.endBattle();
      }

      if (turnIndex == 0) await battleManager.enemyAttack(showMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: HealthBar(
              hp: battleManager.enemy.currentHP,
              maxHp: battleManager.enemy.stats.maxHp.toInt(),
              label:
                  '${battleManager.enemy.name} (Lvl ${battleManager.enemy.level})',
            ),
          ),
          const SizedBox(height: 16),

          // 🔥 Enemy image scales to fit available space
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.contain,
                child: widget.enemy.imageWidget,
              ),
            ),
          ),

          // 🔥 Message section
          Flexible(
            flex: 1,
            child: SizedBox(
              height: 120,
              child:
                  modalMessage != null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            modalMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontFamily: 'Ithica',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          // if (_modalCompleter != null &&
                          // !_modalCompleter!.isCompleted)
                          // const Text(
                          // 'Press Action to continue',
                          // style: TextStyle(
                          // color: Colors.white70,
                          // fontFamily: 'Ithica',
                          // fontSize: 16,
                          // ),
                          // ),
                        ],
                      )
                      : const SizedBox(),
            ),
          ),

          // 🔥 Party row
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 8),
          //   child: Wrap(
          //     alignment: WrapAlignment.center,
          //     spacing: 8,
          //     children:
          //         battleManager.party.map((member) {
          //           return SizedBox(
          //             width: 100,
          //             child: HealthBar(
          //               hp: member.currentHP,
          //               maxHp: member.stats.maxHp.toInt(),
          //               label: member.name,
          //             ),
          //           );
          //         }).toList(),
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children:
                  battleManager.party.asMap().entries.map((entry) {
                    final i = entry.key;
                    final member = entry.value;
                    final isActive = i == turnIndex;

                    return SizedBox(
                      width: 100,
                      child: HealthBar(
                        hp: member.currentHP,
                        maxHp: member.stats.maxHp.toInt(),
                        label: member.name,
                        isActive: isActive,
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Text(
          //   'Turn: ${battleManager.party[turnIndex].name}',
          //   style: const TextStyle(color: Colors.white70, fontFamily: 'Ithica'),
          // ),
          const SizedBox(height: 12),

          // 🔥 Battle menu (let it wrap if needed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child:
                attackMenuOpen
                    ? _buildAttackMenu()
                    : itemMenuOpen
                    ? _buildItemMenu()
                    : _buildMainMenu(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );

    //   return Material(
    //     color: Colors.black.withOpacity(0.95),
    //     child: Center(
    //       child: AnimatedBuilder(
    //         animation: battleManager,
    //         builder: (_, __) {
    //           return Column(
    //             children: [
    //               SizedBox(height: 32),
    //               Padding(
    //                 padding: const EdgeInsets.only(top: 32.0),
    //                 child: Column(
    //                   children: [
    //                     HealthBar(
    //                       hp: battleManager.enemy.currentHP,
    //                       maxHp: battleManager.enemy.stats.maxHp.toInt(),
    //                       label:
    //                           '${battleManager.enemy.name} (Lvl ${battleManager.enemy.level})',
    //                     ),
    //                     const SizedBox(height: 48),
    //                     widget.enemy.imageWidget,
    //                   ],
    //                 ),
    //               ),
    //               if (modalMessage != null)
    //                 SizedBox(
    //                   height: 120,
    //                   child: Column(
    //                     mainAxisSize: MainAxisSize.min,
    //                     children: [
    //                       Text(
    //                         modalMessage!,
    //                         style: const TextStyle(
    //                           color: Colors.white,
    //                           fontSize: 22,
    //                           fontFamily: 'Ithica',
    //                         ),
    //                         textAlign: TextAlign.center,
    //                       ),
    //                       const SizedBox(height: 4),
    //                       if (_modalCompleter != null &&
    //                           !_modalCompleter!.isCompleted)
    //                         const Text(
    //                           'Press Action to continue',
    //                           style: TextStyle(
    //                             color: Colors.white70,
    //                             fontFamily: 'Ithica',
    //                             fontSize: 16,
    //                           ),
    //                         ),
    //                     ],
    //                   ),
    //                 )
    //               else
    //                 SizedBox(height: 120),
    //               // Party Health Bars in a row
    //               Row(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 children:
    //                     battleManager.party.map((member) {
    //                       return Padding(
    //                         padding: const EdgeInsets.symmetric(horizontal: 4),
    //                         child: SizedBox(
    //                           width: 100,
    //                           child: HealthBar(
    //                             hp: member.currentHP,
    //                             maxHp: member.stats.maxHp.toInt(),
    //                             label: member.name,
    //                           ),
    //                         ),
    //                       );
    //                     }).toList(),
    //               ),

    //               // const SizedBox(height: 16),
    //               Text(
    //                 'Turn: ${battleManager.party[turnIndex].name}',
    //                 style: const TextStyle(
    //                   color: Colors.white70,
    //                   fontFamily: 'Ithica',
    //                 ),
    //               ),

    //               const SizedBox(height: 12),
    //               // SizedBox(
    //               // height: 150,
    //               Container(
    //                 // margin: const EdgeInsets.only(top: 16),
    //                 padding: const EdgeInsets.all(8),
    //                 // decoration: BoxDecoration(
    //                 // color: Colors.black,
    //                 // border: Border.all(color: Colors.white),
    //                 // borderRadius: BorderRadius.circular(8),
    //                 // ),
    //                 child:
    //                     attackMenuOpen
    //                         ? _buildAttackMenu()
    //                         : itemMenuOpen
    //                         ? _buildItemMenu()
    //                         : _buildMainMenu(),
    //               ),

    //               SizedBox(height: 64),
    //             ],
    //           );
    //         },
    //       ),
    //     ),
    //   );
  }

  Widget _buildAttackMenu() {
    final currentChar = battleManager.party[turnIndex];
    return Container(
      width: double.infinity,
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(currentChar.attacks.length, (i) {
          final attack = currentChar.attacks[i];
          final selected = i == attackIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Text(
              '${attack.name} (${(currentChar.stats.strength * attack.power).toInt()} dmg)',
              style: TextStyle(
                fontFamily: 'Ithica',
                fontSize: 22,
                color: selected ? Colors.white : Colors.white,
                decoration:
                    selected ? TextDecoration.underline : TextDecoration.none,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildItemMenu() {
    final filteredItems =
        mainInventory.where((item) => item.type != ItemType.currency).toList();

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize:
                  MainAxisSize.min, // 👈 important: let row size to its content
              children: List.generate(filteredItems.length, (i) {
                final selected = i == selectedIndex;
                final item = filteredItems[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: 'Ithica',
                      fontSize: 22,
                      color: Colors.white,
                      decoration:
                          selected
                              ? TextDecoration.underline
                              : TextDecoration.none,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildItemMenu() {
  //   final filteredItems =
  //       mainInventory.where((item) => item.type != ItemType.currency).toList();

  //   // return Column(
  //   // crossAxisAlignment: CrossAxisAlignment.start,
  //   return Container(
  //     width: double.infinity,
  //     child: Row(
  //       // crossAxisAlignment: CrossAxisAlignment.
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: List.generate(filteredItems.length, (i) {
  //         final selected = i == selectedIndex;
  //         final item = filteredItems[i];
  //         return Padding(
  //           padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
  //           child: Text(
  //             '${item.name}',
  //             style: TextStyle(
  //               fontFamily: 'Ithica',
  //               fontSize: 22,
  //               color: selected ? Colors.white : Colors.white,
  //               decoration:
  //                   selected ? TextDecoration.underline : TextDecoration.none,
  //               fontWeight: selected ? FontWeight.bold : FontWeight.normal,
  //             ),
  //           ),
  //         );
  //       }),
  //     ),
  //   );
  // }

  Widget _buildMainMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(commands.length, (i) {
        final selected = i == selectedIndex;
        return SizedBox(
          // width: 75,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Text(
              textAlign: TextAlign.center,
              commands[i],
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'Ithica',
                decoration:
                    selected ? TextDecoration.underline : TextDecoration.none,
                color: selected ? Colors.white : Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
