import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/game/characters/main_player.dart';
import 'package:game/models/items.dart';
import 'package:game/services/settings_service.dart';
import 'package:gamepads/gamepads.dart';

class PauseMenu extends StatefulWidget {
  final MainPlayer player;

  const PauseMenu({super.key, required this.player});

  @override
  State<PauseMenu> createState() => PauseMenuState();
}

class PauseMenuState extends State<PauseMenu> {
  int selectedTab = 0;

  final List<String> tabs = ['Inventory', 'Equipment', 'Party'];

  final SettingsService settings = SettingsService();
  // StreamSubscription<GamepadEvent>? _gamepadSub;
  // Set<String> _activeInputs = {};
  int selectedInventoryIndex = 0;
  int selectedPartyIndex = 0;
  bool selectingPartyMember = false;
  late ScrollController _inventoryScrollController;
  late ScrollController _partyDialogScrollController;
  Completer<BattleCharacter?>? _partySelectionCompleter;
  List<BattleCharacter> _dialogParty = [];

  @override
  void initState() {
    super.initState();
    _inventoryScrollController = ScrollController();
    _partyDialogScrollController = ScrollController();
  }

  @override
  void dispose() {
    // RawKeyboard.instance.removeListener(_onKey);
    // _gamepadSub?.cancel();
    super.dispose();
  }

  void handleInput(String input) {
    final up = settings.getBinding('MoveUp');
    final down = settings.getBinding('MoveDown');
    final left = settings.getBinding('MoveLeft');
    final right = settings.getBinding('MoveRight');
    final action = settings.getBinding('Action');

    final isUp = input == up || input == 'Arrow Up';
    final isDown = input == down || input == 'Arrow Down';
    final isLeft = input == left || input == 'Arrow Left';
    final isRight = input == right || input == 'Arrow Right';
    final isAction = input == action || input == 'Enter' || input == 'Space';

    if (selectingPartyMember) {
      if (isUp || isDown) {
        setState(() {
          selectedPartyIndex =
              (selectedPartyIndex + (isDown ? 1 : -1) + _dialogParty.length) %
              _dialogParty.length;
          _partyDialogScrollController.animateTo(
            selectedPartyIndex * 56.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
          );
        });
      } else if (isAction) {
        if (!_partySelectionCompleter!.isCompleted) {
          Navigator.of(context).pop();
          _partySelectionCompleter!.complete(_dialogParty[selectedPartyIndex]);
        }
      } else if (input == settings.getBinding('Back') || input == 'Backspace') {
        if (!_partySelectionCompleter!.isCompleted) {
          Navigator.of(context).pop();
          _partySelectionCompleter!.complete(null); // user canceled
        }
      }
      return;
    }

    // Handle inventory
    if (selectedTab == 0) {
      final items =
          widget.player.inventory
              .where((item) => item.type != ItemType.currency)
              .toList();

      if (isUp || isDown) {
        setState(() {
          selectedInventoryIndex =
              (selectedInventoryIndex + (isDown ? 1 : -1) + items.length) %
              items.length;
          _inventoryScrollController.animateTo(
            selectedInventoryIndex * 56.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        });
      } else if (isAction && items.isNotEmpty) {
        _useItem(items[selectedInventoryIndex]);
      }
    }

    // Tab switching
    if (isLeft || isRight) {
      setState(() {
        selectedTab =
            (selectedTab + (isRight ? 1 : -1) + tabs.length) % tabs.length;
      });
    }

    if (selectedTab == 2) {
      final party = [widget.player, ...widget.player.currentParty];

      if (isUp || isDown) {
        setState(() {
          selectedPartyStatsIndex =
              (selectedPartyStatsIndex + (isDown ? 1 : -1) + party.length) %
              party.length;

          if (_partyStatsScrollController.hasClients) {
            _partyStatsScrollController.animateTo(
              selectedPartyStatsIndex * 120.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          }
        });
      }

      return; // prevent fall-through
    }
  }

  Future<BattleCharacter?> _selectPartyMember(List<BattleCharacter> party) {
    int selectedIndex = 0;
    final controller = ScrollController();

    return showDialog<BattleCharacter>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        void updateSelection(int direction) {
          selectedIndex =
              (selectedIndex + direction + party.length) % party.length;
          controller.animateTo(
            selectedIndex * 56.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
          );
          (context as Element).markNeedsBuild();
        }

        void onInput(RawKeyEvent input) {
          final up = settings.getBinding('MoveUp');
          final down = settings.getBinding('MoveDown');
          final action = settings.getBinding('Action');

          if (input == up || input == 'Arrow Up') {
            updateSelection(-1);
          } else if (input == down || input == 'Arrow Down') {
            updateSelection(1);
          } else if (input == action || input == 'Enter' || input == 'Space') {
            Navigator.of(context).pop(party[selectedIndex]);
          }
        }

        RawKeyboard.instance.addListener(onInput);

        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Use on who?',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            height: 250,
            child: ListView.builder(
              controller: controller,
              itemCount: party.length,
              itemBuilder: (context, i) {
                final member = party[i];
                return Container(
                  color:
                      i == selectedIndex ? Colors.amber.withOpacity(0.2) : null,
                  child: ListTile(
                    title: Text(
                      member.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'HP: ${member.currentHP}/${member.stats.maxHp.toInt()}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () => Navigator.pop(context, member),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _useItem(Item item) {
    final party = [
      widget.player as BattleCharacter,
      ...(widget.player.currentParty as List<BattleCharacter>),
    ];
    setState(() {
      selectingPartyMember = true;
      _dialogParty = party as List<BattleCharacter>;
      selectedPartyIndex = 0;
      _partySelectionCompleter = Completer<BattleCharacter?>();
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.black,
                title: const Text(
                  'Use on who?',
                  style: TextStyle(color: Colors.white),
                ),
                content: Container(
                  width:
                      double.maxFinite, // ensures no intrinsic width measuring
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                    minHeight: 100,
                  ),
                  child: ListView.builder(
                    controller: _partyDialogScrollController,
                    itemCount: _dialogParty.length,
                    itemBuilder: (context, i) {
                      final member = _dialogParty[i];
                      final isSelected = i == selectedPartyIndex;

                      return Scrollbar(
                        controller: _partyDialogScrollController,
                        thumbVisibility: true,
                        child: Container(
                          color:
                              isSelected ? Colors.amber.withOpacity(0.2) : null,
                          child: ListTile(
                            title: Text(
                              member.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'HP: ${member.currentHP}/${member.stats.maxHp.toInt()}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            onTap: () {
                              if (!_partySelectionCompleter!.isCompleted) {
                                Navigator.of(context).pop();
                                _partySelectionCompleter!.complete(member);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
    ).then((_) {
      selectingPartyMember = false;
      _dialogParty = [];
    });

    _partySelectionCompleter!.future.then((selected) {
      if (selected != null) {
        setState(() {
          selected.heal(item.value ?? 0);
          widget.player.removeItem(item);
        });
      }
    });
  }

  Widget _buildInventory() {
    final items =
        widget.player.inventory
            .where((item) => item.type != ItemType.currency)
            .toList();

    if (items.isEmpty) {
      return const Text(
        'No items in inventory.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return ListView.builder(
      controller: _inventoryScrollController,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = index == selectedInventoryIndex;

        return Container(
          color:
              isSelected ? Colors.amber.withOpacity(0.2) : Colors.transparent,
          child: ListTile(
            title: Text(item.name, style: const TextStyle(color: Colors.white)),
            trailing: TextButton(
              onPressed: () => _useItem(item),
              child: const Text('Use', style: TextStyle(color: Colors.amber)),
            ),
          ),
        );
      },
      shrinkWrap: true,
    );
  }

  Widget _buildEquipment() {
    return const Text(
      'Equipment screen coming soon.',
      style: TextStyle(color: Colors.white70),
    );
  }

  int selectedPartyStatsIndex = 0;
  final ScrollController _partyStatsScrollController = ScrollController();

  Widget _buildPartyStats() {
    List<BattleCharacter> party = [
      widget.player,
      ...widget.player.currentParty,
    ];

    return SizedBox(
      height: 300, // or any reasonable value
      child: ListView.builder(
        controller: _partyStatsScrollController,
        itemCount: party.length,
        itemBuilder: (context, i) {
          final member = party[i];
          final isSelected = i == selectedPartyStatsIndex;

          return Container(
            color: isSelected ? Colors.amber.withOpacity(0.2) : null,
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
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
                const Text('Attacks:', style: TextStyle(color: Colors.white70)),
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
        },
      ),
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
