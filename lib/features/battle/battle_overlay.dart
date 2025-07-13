import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/features/battle/battle_manager.dart';
import 'package:game/features/characters/battle_character.dart';
import 'package:game/features/characters/enemies/test_enemy.dart' as game_enemy;
import 'package:game/features/characters/main_player.dart';
import 'package:game/features/characters/party/test_friend.dart';
import 'package:game/features/items/items.dart';
import 'package:game/main.dart';
import 'package:game/services/attacks.dart';
import 'package:game/services/character_stats.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/health_bar.dart';
import 'package:gamepads/gamepads.dart';

class BattleOverlay extends StatefulWidget {
  final TrustFall game;
  final List<BattleCharacter> party;
  final game_enemy.Enemy enemy;

  BattleOverlay({
    super.key,
    required this.game,
    required this.party,
    required this.enemy,
  });

  @override
  State<BattleOverlay> createState() => _BattleOverlayState();
}

class _BattleOverlayState extends State<BattleOverlay> {
  late final BattleManager battleManager;
  int selectedIndex = 0;
  bool itemMenuOpen = false;
  bool attackMenuOpen = false;
  int attackIndex = 0;
  String? battleMessage;
  int turnIndex = 0;
  StreamSubscription<GamepadEvent>? _gamepadSub;
  final SettingsService settings = SettingsService();
  List<String> queuedMessages = [];
  bool awaitingInputForMessage = false;

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

  void queueMessage(String message) {
    queuedMessages.add(message);
    if (!awaitingInputForMessage) {
      showNextMessage();
    }
  }

  void showNextMessage() {
    if (queuedMessages.isNotEmpty) {
      setState(() {
        battleMessage = queuedMessages.removeAt(0);
        awaitingInputForMessage = true;
      });
    } else {
      setState(() {
        battleMessage = null;
        awaitingInputForMessage = false;
      });
    }
  }

  void _handleSelection() {
    final currentChar = battleManager.party[turnIndex];

    if (itemMenuOpen) {
      final item = mainInventory[selectedIndex];
      battleManager.useItemOn(currentChar, item);
      setState(() {
        battleMessage = '${currentChar.name} used ${item.name}!';
        itemMenuOpen = false;
        selectedIndex = 0;
      });
      _endTurn();
    } else if (attackMenuOpen) {
      final attack = currentChar.attacks[attackIndex];
      battleManager.attackEnemy(currentChar, attack);

      setState(() {
        battleMessage = '${currentChar.name} used ${attack.name}!';
        attackMenuOpen = false;
        attackIndex = 0;
      });

      _endTurn();
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
            battleManager.battleEnded = true;
            battleMessage = '${currentChar.name} ran away!';
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) widget.game.endBattle();
          });
          break;
      }
    }
  }

  void _endTurn() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        turnIndex++;
        battleMessage = null;

        // If all party members have acted, let enemy go
        if (turnIndex >= battleManager.party.length) {
          turnIndex = 0;
          battleManager.playerTurn = false;

          Future.delayed(const Duration(seconds: 1), () {
            battleManager.enemyAttack();
            setState(() {
              battleManager.playerTurn = true;
            });
          });
        }
      });
    });
  }

  Widget _buildPartyStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          battleManager.party.map((member) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.name} (Lvl ${member.stats.level})',
                  style: const TextStyle(color: Colors.white),
                ),
                HealthBar(
                  hp: member.currentHP,
                  maxHp: member.stats.maxHp.toInt(),
                  label: 'HP',
                ),

                const SizedBox(height: 8),
              ],
            );
          }).toList(),
    );
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
                SizedBox(
                  height: 64,
                  width: 64,
                  child: widget.enemy.imageWidget,
                ),

                const SizedBox(height: 8),
                Text(
                  '${battleManager.enemy.name} (Lvl ${battleManager.enemy.level})',
                  style: const TextStyle(color: Colors.white),
                ),
                HealthBar(
                  hp: battleManager.enemy.currentHP,
                  maxHp: battleManager.enemy.stats.maxHp.toInt(),
                  label: 'Enemy HP',
                ),
                const SizedBox(height: 16),
                _buildPartyStats(),
                const SizedBox(height: 24),
                if (battleMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      battleMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Text(
                  'Turn: ${battleManager.party[turnIndex].name}',
                  style: const TextStyle(color: Colors.white70),
                ),

                if (battleManager.battleEnded)
                  Text(
                    battleManager.party.any((c) => c.isAlive)
                        ? 'You won!'
                        : 'You lost!',
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
                        attackMenuOpen
                            ? _buildAttackMenu()
                            : itemMenuOpen
                            ? _buildItemMenu()
                            : _buildMainMenu(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttackMenu() {
    final currentChar = battleManager.party.first;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(mainInventory.length, (i) {
        final selected = i == selectedIndex;
        final item = mainInventory[i];
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
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 3.5,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: List.generate(commands.length, (i) {
        final selected = i == selectedIndex;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: selected ? Colors.amber : Colors.white),
            borderRadius: BorderRadius.circular(6),
            color: Colors.black,
          ),
          padding: const EdgeInsets.all(6),
          child: Center(
            child: Text(
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
