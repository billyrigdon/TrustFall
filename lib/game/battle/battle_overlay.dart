import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game/game/battle/battle_action.dart';
import 'package:game/game/battle/battle_manager.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/battle_status.dart';
import 'package:game/models/enemy.dart' as game_enemy;
import 'package:game/game/main_player/main_player.dart';
import 'package:game/models/items.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/health_bar.dart';
import 'package:game/widgets/mental_power_bar.dart';

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
  bool bankMenuOpen = false;
  int attackIndex = 0;
  int bankIndex = 0;
  int turnIndex = 0;
  bool selectingItemAction = false;
  bool targetingAlly = false;
  int selectedItemIndex = 0;
  int selectedAllyIndex = 0;

  List<BattleAction> playerActions = [];

  final SettingsService settings = SettingsService();
  List<String> queuedMessages = [];
  // bool didEnemyAttack = false;

  String? modalMessage;
  Completer<void>? _modalCompleter;

  List<String> commands = ['Attack', 'Bank', 'Run'];

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
      commands = ['Attack', 'Bank', 'Items', 'Run'];
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
      bankMenuOpen = false;
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

    // 🔙 Back Navigation
    if (isBack) {
      if (targetingAlly) {
        setState(() {
          targetingAlly = false;
          selectedAllyIndex = 0;
        });
        return;
      }
      if (selectingItemAction) {
        setState(() {
          selectingItemAction = false;
          selectedIndex = 0;
        });
        return;
      }
      if (itemMenuOpen || attackMenuOpen || bankMenuOpen) {
        setState(() {
          itemMenuOpen = false;
          attackMenuOpen = false;
          bankMenuOpen = false;
          selectedIndex = 0;
          attackIndex = 0;
          bankIndex = 0;
        });
        return;
      }
    }

    // 🧺 Item Menu Navigation
    if (itemMenuOpen && !selectingItemAction && !targetingAlly) {
      if (isRight) {
        setState(() {
          selectedIndex = (selectedIndex + 1) % mainInventory.length;
          _scrollToSelectedItem(selectedIndex);
        });
        return;
      } else if (isLeft) {
        setState(() {
          selectedIndex =
              (selectedIndex - 1 + mainInventory.length) % mainInventory.length;
          _scrollToSelectedItem(selectedIndex);
        });
        return;
      }
    }

    // 🍴 Submenu: Use On / Throw
    if (itemMenuOpen && selectingItemAction && !targetingAlly) {
      if (isRight || isLeft) {
        setState(() {
          selectedIndex = (selectedIndex == 0) ? 1 : 0;
        });
        return;
      }
    }

    // 👥 Use On — Party Member Selection
    if (targetingAlly) {
      if (isRight) {
        setState(() {
          selectedAllyIndex =
              (selectedAllyIndex + 1) % battleManager.party.length;
        });
        return;
      } else if (isLeft) {
        setState(() {
          selectedAllyIndex =
              (selectedAllyIndex - 1 + battleManager.party.length) %
              battleManager.party.length;
        });
        return;
      }
    }

    if (isRight && !itemMenuOpen && !attackMenuOpen && !bankMenuOpen) {
      setState(() => selectedIndex = (selectedIndex + 1) % commands.length);
    } else if (isLeft && !itemMenuOpen && !attackMenuOpen && !bankMenuOpen) {
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
    } else if (isRight && bankMenuOpen) {
      final currentChar = battleManager.party[turnIndex];

      setState(() => bankIndex = (bankIndex + 1) % currentChar.bank.length);
    } else if (isLeft && bankMenuOpen) {
      final currentChar = battleManager.party[turnIndex];

      setState(
        () =>
            bankIndex =
                (bankIndex - 1 + currentChar.bank.length) %
                currentChar.bank.length,
      );
    } else if (isAction) {
      // if (modalMessage == null) {
      _handleSelection();
      // }
    }
  }

  // void _handleSelection() async {
  //   final currentChar = battleManager.party[turnIndex];

  //   if (itemMenuOpen) {
  //     final item = mainInventory[selectedIndex];

  //     await battleManager.useItemOn(currentChar, item, showMessage);

  //     setState(() {
  //       itemMenuOpen = false;
  //       selectedIndex = 0;
  //       if (mainInventory.isEmpty) {
  //         commands = ['Attack', 'Run'];
  //       }
  //     });

  //     await _endTurn();
  //   } else if (attackMenuOpen) {
  //     final attack = currentChar.attacks[attackIndex];
  //     await battleManager.attackEnemy(currentChar, attack, showMessage);

  //     setState(() {
  //       attackMenuOpen = false;
  //       attackIndex = 0;
  //     });

  //     await _endTurn();
  //   } else if (bankMenuOpen) {
  //     final bankMove = currentChar.bank[bankIndex];
  //     await battleManager.mentallyAttackEnemy(
  //       currentChar,
  //       bankMove,
  //       showMessage,
  //     );

  //     setState(() {
  //       bankMenuOpen = false;
  //       bankIndex = 0;
  //     });

  //     await _endTurn();
  //   } else {
  //     switch (commands[selectedIndex]) {
  //       case 'Attack':
  //         setState(() {
  //           attackMenuOpen = true;
  //           attackIndex = 0;
  //         });
  //         break;
  //       case 'Bank':
  //         setState(() {
  //           bankMenuOpen = true;
  //           bankIndex = 0;
  //         });
  //         break;
  //       case 'Items':
  //         setState(() {
  //           itemMenuOpen = true;
  //           selectedIndex = 0;
  //         });
  //         break;
  //       case 'Run':
  //         setState(() {
  //           attackMenuOpen = false;
  //           itemMenuOpen = false;
  //           selectedIndex = 0;
  //         });

  //         await showMessage(
  //           '${currentChar.name} ran away!',
  //           requireConfirmation: true,
  //         );
  //         battleManager.battleEnded = true;

  //         if (mounted)
  //           widget.game
  //               .endBattle(); // optional: delay this if you want confirmation
  //         return; // ✅ Early return to prevent continuing
  //     }
  //   }
  // }

  Future<void> _resolveTurn() async {
    for (final member in battleManager.party) {
      member.decrementStatuses();
    }
    battleManager.enemy.decrementStatuses();

    // Collect enemy action
    final enemy = battleManager.enemy;
    final randomAttack = enemy.attacks[Random().nextInt(enemy.attacks.length)];
    final target =
        battleManager.party.where((c) => c.isAlive).toList()..shuffle();
    if (target.isNotEmpty) {
      battleManager.pendingActions.add(
        BattleAction(
          actor: enemy,
          type: ActionType.attack,
          attack: randomAttack,
        ),
      );
    }

    // Merge and sort by speed
    final allActions = [...playerActions, ...battleManager.pendingActions]
      ..sort((a, b) => b.speed.compareTo(a.speed)); // higher speed first

    for (final action in allActions) {
      if (!action.actor.isAlive) continue;

      final result = await action.actor.canAct(showMessage);
      if (!result.canAct) continue;

      final actor = action.actor;
      final attack = action.attack;
      final item = action.item;

      // 🧠 Confused: force random target
      BattleCharacter? randomTarget;
      if (result.forceRandomTarget) {
        final possibleTargets =
            battleManager.party.where((c) => c.isAlive).toList();
        if (possibleTargets.isNotEmpty) {
          randomTarget =
              possibleTargets[Random().nextInt(possibleTargets.length)];
        }
      }

      // 😡 Rage: override to Attack if not already
      if (result.forceAttack && action.type != ActionType.attack) {
        if (attack != null) {
          await battleManager.attackEnemy(actor, attack, showMessage);
        } else {
          await showMessage(
            "${actor.name} is enraged but doesn't know how to fight! 😬",
          );
        }
        continue;
      }

      switch (action.type) {
        case ActionType.attack:
          await battleManager.attackEnemy(
            action.actor,
            action.attack!,
            showMessage,
          );
          break;
        case ActionType.bank:
          await battleManager.mentallyAttackEnemy(
            action.actor,
            action.attack!,
            showMessage,
          );
          break;
        case ActionType.item:
          await battleManager.useItemOn(
            action.actor,
            action.item!,
            showMessage,
          );
          break;
        case ActionType.throwItem:
          await battleManager.throwItem(actor, item!, showMessage);
          break;

        case ActionType.run:
          // Handle run early?
          break;
      }

      if (battleManager.battleEnded) widget.game.endBattle();
    }

    playerActions.clear();
    battleManager.pendingActions.clear();
    battleManager.playerTurn = true;
  }

  void _handleSelection() async {
    final currentChar = battleManager.party[turnIndex];

    if (itemMenuOpen) {
      if (targetingAlly) {
        // Ally target confirmed
        final item = mainInventory[selectedItemIndex];
        final target = battleManager.party[selectedAllyIndex];

        playerActions.add(
          BattleAction(
            actor: currentChar,
            type: ActionType.item,
            item: item,
            target: target,
          ),
        );
        setState(() {
          targetingAlly = false;
          selectingItemAction = false;
          itemMenuOpen = false;
        });
      } else if (selectingItemAction) {
        final item = mainInventory[selectedItemIndex];

        if (selectedIndex == 1) {
          // Throw selected
          playerActions.add(
            BattleAction(
              actor: currentChar,
              type: ActionType.throwItem,
              item: item,
            ),
          );
          setState(() {
            selectingItemAction = false;
            itemMenuOpen = false;
          });
        } else {
          // Use On selected → go to target selection
          setState(() {
            targetingAlly = true;
            selectedAllyIndex = 0;
          });
          return;
        }
      } else {
        // First item click: go to submenu
        setState(() {
          selectingItemAction = true;
          selectedItemIndex = selectedIndex;
          selectedIndex = 0;
        });
        return;
      }
    } else if (attackMenuOpen) {
      final attack = currentChar.attacks[attackIndex];
      playerActions.add(
        BattleAction(
          actor: currentChar,
          type: ActionType.attack,
          attack: attack,
        ),
      );
    } else if (bankMenuOpen) {
      final bankMove = currentChar.bank[bankIndex];
      playerActions.add(
        BattleAction(
          actor: currentChar,
          type: ActionType.bank,
          attack: bankMove,
        ),
      );
    } else {
      switch (commands[selectedIndex]) {
        case 'Attack':
          setState(() => attackMenuOpen = true);
          return;
        case 'Bank':
          setState(() => bankMenuOpen = true);
          return;
        case 'Items':
          setState(() => itemMenuOpen = true);
          return;
        case 'Run':
          await showMessage(
            '${currentChar.name} ran away!',
            requireConfirmation: true,
          );
          battleManager.battleEnded = true;
          if (mounted) widget.game.endBattle();
          return;
      }
    }

    // Reset UI state
    setState(() {
      itemMenuOpen = false;
      attackMenuOpen = false;
      bankMenuOpen = false;
      targetingAlly = false;
      selectingItemAction = false;
      selectedIndex = 0;
      attackIndex = 0;
      bankIndex = 0;
    });

    // Next party member
    turnIndex++;

    // Done selecting all actions?
    if (turnIndex >= battleManager.party.length) {
      turnIndex = 0;
      await _resolveTurn();
    }
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

  Widget _buildBankMenu() {
    final currentChar = battleManager.party[turnIndex];
    return Container(
      width: double.infinity,
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(currentChar.bank.length, (i) {
          final bankMove = currentChar.bank[i];
          final selected = i == bankIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Text(
              '${bankMove.name} (${(currentChar.stats.intelligence * bankMove.power).toInt()} dmg)',
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

  // Widget _buildItemMenu() {
  //   final filteredItems =
  //       mainInventory.where((item) => item.type != ItemType.currency).toList();

  //   return SizedBox(
  //     height: 48,
  //     width: double.infinity,
  //     child: Center(
  //       child: SingleChildScrollView(
  //         controller: _scrollController,
  //         scrollDirection: Axis.horizontal,
  //         child: Align(
  //           alignment: Alignment.center,
  //           child: Row(
  //             mainAxisSize:
  //                 MainAxisSize.min, // 👈 important: let row size to its content
  //             children: List.generate(filteredItems.length, (i) {
  //               final selected = i == selectedIndex;
  //               final item = filteredItems[i];
  //               return Padding(
  //                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
  //                 child: Text(
  //                   item.name,
  //                   style: TextStyle(
  //                     fontFamily: 'Ithica',
  //                     fontSize: 22,
  //                     color: Colors.white,
  //                     decoration:
  //                         selected
  //                             ? TextDecoration.underline
  //                             : TextDecoration.none,
  //                     fontWeight:
  //                         selected ? FontWeight.bold : FontWeight.normal,
  //                   ),
  //                 ),
  //               );
  //             }),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildItemMenu() {
    final filteredItems =
        mainInventory.where((item) => item.type != ItemType.currency).toList();

    if (targetingAlly) {
      return _buildItemTargetMenu(filteredItems[selectedItemIndex]);
    }

    if (selectingItemAction) {
      return _buildItemActionMenu(filteredItems[selectedItemIndex]);
    }

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildItemActionMenu(Item item) {
    final actions = ['Use On', 'Throw'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(actions.length, (i) {
        final selected = i == selectedIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            actions[i],
            style: TextStyle(
              fontFamily: 'Ithica',
              fontSize: 22,
              color: Colors.white,
              decoration:
                  selected ? TextDecoration.underline : TextDecoration.none,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildItemTargetMenu(Item item) {
    return Container(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children:
            battleManager.party.asMap().entries.map((entry) {
              final i = entry.key;
              final member = entry.value;
              final selected = i == selectedAllyIndex;

              return Column(
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      fontFamily: 'Ithica',
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      decoration: selected ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

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

  String _statusLabel(BattleStatus status) {
    switch (status.type) {
      case BattleStatusType.stunned:
        return 'Stunned';
      case BattleStatusType.confused:
        return 'Confused';
      case BattleStatusType.embarrassed:
        return 'Embarrassed';
      case BattleStatusType.charmed:
        return 'Charmed';
      case BattleStatusType.rage:
        return 'Raging';
      case BattleStatusType.selfDoubt:
        return 'Doubting';
      case BattleStatusType.asleep:
        return 'Asleep';
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
          if (battleManager.enemy.statuses.any((s) => s.duration > 0))
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Wrap(
                spacing: 4,
                children:
                    battleManager.enemy.statuses
                        .where((s) => s.duration > 0)
                        .map(
                          (s) => Text(
                            _statusLabel(s),
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                              fontFamily: 'Ithica',
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  Platform.isAndroid || Platform.isIOS
                                      ? 22
                                      : 48,
                              fontFamily: 'Ithica',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                        ],
                      )
                      : const SizedBox(),
            ),
          ),

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
                      child: Column(
                        children: [
                          if (member.statuses.any((s) => s.duration > 0))
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Wrap(
                                spacing: 4,
                                children:
                                    member.statuses
                                        .where((s) => s.duration > 0)
                                        .map(
                                          (s) => Text(
                                            _statusLabel(s),
                                            style: const TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 12,
                                              fontFamily: 'Ithica',
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),

                          HealthBar(
                            hp: member.currentHP,
                            maxHp: member.stats.maxHp.toInt(),
                            label: member.name,
                            isActive: isActive,
                          ),

                          MentalPowerBar(
                            mp: member.currentMP,
                            maxMP: member.stats.maxMP.toInt(),
                          ),
                        ],
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
                    : bankMenuOpen
                    ? _buildBankMenu()
                    : itemMenuOpen
                    ? _buildItemMenu()
                    : _buildMainMenu(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _endTurn() async {
    turnIndex++;
    if (turnIndex >= battleManager.party.length) {
      turnIndex = 0;
      battleManager.playerTurn = false;

      if (battleManager.battleEnded) {
        if (mounted) widget.game.endBattle();
      }

      if (turnIndex == 0) {
        await battleManager.enemyAttack(showMessage);
      }
    }
  }
}
