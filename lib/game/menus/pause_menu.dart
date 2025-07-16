import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/game/characters/battle_character.dart';
import 'package:game/game/characters/main_player.dart';
import 'package:game/game/items/items.dart';
import 'package:game/services/settings_service.dart';
import 'package:gamepads/gamepads.dart';

class PauseMenu extends StatefulWidget {
  final MainPlayer player;

  const PauseMenu({super.key, required this.player});

  @override
  State<PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<PauseMenu> {
  int selectedTab = 0;

  final List<String> tabs = ['Inventory', 'Equipment', 'Party'];

  final SettingsService settings = SettingsService();
  StreamSubscription<GamepadEvent>? _gamepadSub;
  Set<String> _activeInputs = {};

  @override
  void initState() {
    super.initState();
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
    if (event is! RawKeyDownEvent) return;

    final label =
        event.logicalKey.keyLabel.isEmpty
            ? event.logicalKey.debugName ?? ''
            : event.logicalKey.keyLabel;

    _handleInput(label);
  }

  void _onGamepad(GamepadEvent event) {
    final typeStr = event.type.toString();
    final isAxis = typeStr.contains('axis') || typeStr.contains('analog');
    final isButton = event.type == KeyType.button;

    if (isAxis) {
      final positive = '${event.gamepadId}:${event.key}:+';
      final negative = '${event.gamepadId}:${event.key}:-';

      if (event.value >= 0.9) {
        _activeInputs.add(positive);
        _activeInputs.remove(negative);
        _handleGamepadInput(positive);
      } else if (event.value <= -0.9) {
        _activeInputs.add(negative);
        _activeInputs.remove(positive);
        _handleGamepadInput(negative);
      } else {
        _activeInputs.remove(positive);
        _activeInputs.remove(negative);
      }
    }

    if (isButton) {
      final input = '${event.gamepadId}:${event.key}';

      if (event.value == 1.0) {
        _activeInputs.add(input);
        _handleGamepadInput(input);
      } else if (event.value == 0.0) {
        _activeInputs.remove(input);
      }
    }
  }

  void _handleGamepadInput(String input) {
    final left = settings.getBinding('MoveLeft');
    final right = settings.getBinding('MoveRight');

    if (input == left) {
      setState(
        () => selectedTab = (selectedTab - 1 + tabs.length) % tabs.length,
      );
    } else if (input == right) {
      setState(() => selectedTab = (selectedTab + 1) % tabs.length);
    }
  }

  void _handleInput(String input) {
    final left = settings.getBinding('MoveLeft');
    final right = settings.getBinding('MoveRight');

    final isLeft = input == left || input == 'Arrow Left' || input == '←';
    final isRight = input == right || input == 'Arrow Right' || input == '→';

    if (isLeft) {
      setState(
        () => selectedTab = (selectedTab - 1 + tabs.length) % tabs.length,
      );
    } else if (isRight) {
      setState(() => selectedTab = (selectedTab + 1) % tabs.length);
    }
  }

  void _useItem(Item item) async {
    final List<BattleCharacter> party = [
      widget.player,
      ...widget.player.currentParty,
    ];

    if (item.isConsumable) {
      final selected = await showDialog<BattleCharacter>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'Use on who?',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    party.map((member) {
                      return ListTile(
                        title: Text(
                          member.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'HP: ${member.currentHP}/${member.stats.maxHp.toInt()}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () => Navigator.pop(context, member),
                      );
                    }).toList(),
              ),
            ),
      );

      if (selected != null) {
        setState(() {
          selected.heal(item.value ?? 0);
          widget.player.removeItem(item);
        });
      }
    }
  }

  Widget _buildInventory() {
    final items = widget.player.inventory;

    if (items.isEmpty) {
      return const Text(
        'No items in inventory.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items.map((item) {
            if (item.type == ItemType.currency) return Container();
            return Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () => _useItem(item),
                  child: const Text(
                    'Use',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildEquipment() {
    return const Text(
      'Equipment screen coming soon.',
      style: TextStyle(color: Colors.white70),
    );
  }

  Widget _buildPartyStats() {
    List<BattleCharacter> party = [
      widget.player,
      ...widget.player.currentParty,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          party.map((member) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${member.name} - Lvl ${member.stats.level}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'HP: ${member.currentHP}/${member.stats.maxHp.toInt()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Text(
                    'Attacks:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  ...member.attacks.map(
                    (a) => Text(
                      '- ${a.name} (${a.type.name}, ${a.power}x)',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildContent() {
    switch (selectedTab) {
      case 0:
        return _buildInventory();
      case 1:
        return _buildEquipment();
      case 2:
        return _buildPartyStats();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paused',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Money: \$${widget.player.money}',
              style: const TextStyle(color: Colors.amber, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(tabs.length, (i) {
                final selected = i == selectedTab;
                return GestureDetector(
                  onTap: () => setState(() => selectedTab = i),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color: selected ? Colors.amber : Colors.white,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: _buildContent())),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
