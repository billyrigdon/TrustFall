import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game/game/battle/battle_manager.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/game/characters/enemies/test_enemy.dart' as game_enemy;
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

  final List<String> commands = ['Attack', 'Items', 'Run'];

  List<Item> get mainInventory {
    final main = battleManager.party.firstWhere((c) => c is MainPlayer);
    return main.inventory;
  }

  @override
  void initState() {
    super.initState();

    battleManager = BattleManager(party: widget.party, enemy: widget.enemy);
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
    });

    _modalCompleter = Completer<void>();

    setState(() {
      modalMessage = message;
    });

    if (!requireConfirmation) {
      // auto-complete after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (_modalCompleter != null && !_modalCompleter!.isCompleted) {
          setState(() => modalMessage = null);
          _modalCompleter!.complete();
        }
      });
    }

    return _modalCompleter!.future;
  }

  void handleInput(String inputLabel) {
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

    if (modalMessage != null) {
      if (isAction &&
          _modalCompleter != null &&
          !_modalCompleter!.isCompleted) {
        setState(() => modalMessage = null);
        _modalCompleter!.complete();
      }
      return;
    }

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
    } else if (isDown && itemMenuOpen) {
      setState(
        () => selectedIndex = (selectedIndex + 1) % mainInventory.length,
      );
    } else if (isUp && itemMenuOpen) {
      setState(
        () =>
            selectedIndex =
                (selectedIndex - 1 + mainInventory.length) %
                mainInventory.length,
      );
    } else if (isDown && attackMenuOpen) {
      final currentChar = battleManager.party[turnIndex];

      setState(
        () => attackIndex = (attackIndex + 1) % currentChar.attacks.length,
      );
    } else if (isUp && attackMenuOpen) {
      final currentChar = battleManager.party[turnIndex];

      setState(
        () =>
            attackIndex =
                (attackIndex - 1 + currentChar.attacks.length) %
                currentChar.attacks.length,
      );
    } else if (isAction) {
      _handleSelection();
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

      await battleManager.enemyAttack(showMessage);
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
            return Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Enemy HP and sprite
                    Column(
                      children: [
                        HealthBar(
                          hp: battleManager.enemy.currentHP,
                          maxHp: battleManager.enemy.stats.maxHp.toInt(),
                          label:
                              '${battleManager.enemy.name} (Lvl ${battleManager.enemy.level})',
                        ),
                        const SizedBox(height: 12),
                        widget.enemy.imageWidget,
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Party Health Bars in a row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          battleManager.party.map((member) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: SizedBox(
                                width: 100,
                                child: HealthBar(
                                  hp: member.currentHP,
                                  maxHp: member.stats.maxHp.toInt(),
                                  label: member.name,
                                ),
                              ),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Turn: ${battleManager.party[turnIndex].name}',
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(8),
                      width: 320,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          attackMenuOpen
                              ? _buildAttackMenu()
                              : itemMenuOpen
                              ? _buildItemMenu()
                              : _buildMainMenu(),
                    ),
                  ],
                ),
                if (modalMessage != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.85),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.amber, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              modalMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (_modalCompleter != null &&
                                !_modalCompleter!.isCompleted)
                              const Text(
                                'Press Action to continue',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttackMenu() {
    final currentChar = battleManager.party[turnIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(currentChar.attacks.length, (i) {
        final attack = currentChar.attacks[i];
        final selected = i == attackIndex;
        return Text(
          '${selected ? '▶' : '  '} ${attack.name} (${(currentChar.stats.strength * attack.power).toInt()} dmg)',
          style: TextStyle(
            color: selected ? Colors.amber : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }),
    );
  }

  Widget _buildItemMenu() {
    final filteredItems =
        mainInventory.where((item) => item.type != ItemType.currency).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(filteredItems.length, (i) {
        final selected = i == selectedIndex;
        final item = filteredItems[i];
        return Text(
          '${selected ? '▶' : '  '} ${item.name}',
          style: TextStyle(
            color: selected ? Colors.amber : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }),
    );
  }

  Widget _buildMainMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(commands.length, (i) {
        final selected = i == selectedIndex;
        return SizedBox(
          width: 72,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: selected ? Colors.amber : Colors.white),
              borderRadius: BorderRadius.circular(6),
              color: Colors.black,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Text(
              textAlign: TextAlign.center,
              commands[i],
              style: TextStyle(
                color: selected ? Colors.amber : Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
