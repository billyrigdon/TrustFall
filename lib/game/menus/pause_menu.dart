import 'dart:async';
import 'package:flame/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/game/main_player/main_player.dart';
import 'package:game/models/equipment.dart';
import 'package:game/models/items.dart';
import 'package:game/services/settings_service.dart';

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
  int selectedInventoryIndex = 0;
  int selectedPartyIndex = 0;
  bool selectingPartyMember = false;
  late ScrollController _inventoryScrollController;
  late ScrollController _partyDialogScrollController;
  Completer<BattleCharacter?>? _partySelectionCompleter;
  List<BattleCharacter> _dialogParty = [];
  int selectedEquipmentIndex = 0;
  late ScrollController _equipmentScrollController;
  List<Equipment> _dialogEquipmentOptions = [];
  int selectedEquipmentDialogIndex = 0;
  Completer<Equipment?>? _equipmentSelectionCompleter;

  @override
  void initState() {
    super.initState();
    _equipmentScrollController = ScrollController();
    _inventoryScrollController = ScrollController();
    _partyDialogScrollController = ScrollController();
  }

  @override
  void dispose() {
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

    if (selectingEquipment) {
      // final back = settings.getBinding('Back');

      if (isUp || isDown) {
        setState(() {
          selectedEquipmentDialogIndex =
              (selectedEquipmentDialogIndex +
                  (isDown ? 1 : -1) +
                  _dialogEquipmentOptions.length) %
              _dialogEquipmentOptions.length;
        });
      } else if (isAction) {
        if (!_equipmentSelectionCompleter!.isCompleted) {
          Navigator.of(context).pop();
          _equipmentSelectionCompleter!.complete(
            _dialogEquipmentOptions[selectedEquipmentDialogIndex],
          );
        }
      }

      return;
    }

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

    if (selectedTab == 1) {
      final slots = EquipmentSlot.values;

      if (isUp || isDown) {
        setState(() {
          selectedEquipmentIndex =
              (selectedEquipmentIndex + (isDown ? 1 : -1) + slots.length) %
              slots.length;
          _equipmentScrollController.animateTo(
            selectedEquipmentIndex * 56.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        });
      } else if (isAction) {
        final slot = slots[selectedEquipmentIndex];
        final hasCompatible = widget.player.inventory
            .whereType<Equipment>()
            .any((e) => e.slot == slot);

        if (hasCompatible) {
          _selectEquipmentForSlot(slot);
        } else if (widget.player.equipped[slot] != null) {
          setState(() {
            final item = widget.player.equipped[slot]!;
            widget.player.addItem(item);
            widget.player.unequip(slot);
            widget.player.saveEquipment();
          });
        }
      } else if (input == settings.getBinding('Back') || input == 'Backspace') {
        Navigator.of(context).pop();
      }

      return;
    }

    if (selectedTab == 2) {
      // final party = [widget.player, ...widget.player.currentParty];

      final List<BattleCharacter> party = [
        widget.player,
        ...widget.player.currentParty.where(
          (c) => c.name != widget.player.name,
        ),
      ];

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

  void _useItem(Item item) {
    final List<BattleCharacter> party = [
      widget.player,
      ...widget.player.currentParty.where((c) => c.name != widget.player.name),
    ];

    setState(() {
      selectingPartyMember = true;
      _dialogParty = party;
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
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Ithica',
                    fontSize: 22,
                  ),
                ),
                content: Container(
                  width: double.maxFinite,
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
                              isSelected ? Colors.white.withOpacity(0.2) : null,
                          child: ListTile(
                            title: Text(
                              member.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Ithica',
                                fontSize: 24,
                              ),
                            ),
                            subtitle: Text(
                              'HP: ${member.currentHP}/${member.stats.maxHp.toInt()}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontFamily: 'Ithica',
                              ),
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
          if (item is Equipment && item.slot != null) {
            selected.equip(item as Equipment);
          } else if (item.value != null && item.value! > 0) {
            selected.heal(item.value!);
          }

          widget.player.removeItem(item);
          widget.player.saveEquipment();
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
        style: TextStyle(
          color: Colors.white70,
          fontFamily: 'Ithica',
          fontSize: 22,
        ),
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
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          child: ListTile(
            title: Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Ithica',
                fontSize: 22,
              ),
            ),
            trailing: TextButton(
              onPressed: () => _useItem(item),
              child: const Text(
                'Use',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Ithica',
                  fontSize: 20,
                ),
              ),
            ),
          ),
        );
      },
      shrinkWrap: true,
    );
  }

  Widget _buildEquipment() {
    final equipmentSlots = EquipmentSlot.values;

    return ListView.builder(
      controller: _equipmentScrollController,
      itemCount: equipmentSlots.length,
      itemBuilder: (context, index) {
        final slot = equipmentSlots[index];
        final equippedItem = widget.player.equipped[slot];
        final isSelected = index == selectedEquipmentIndex;

        return Container(
          color: isSelected ? Colors.white.withOpacity(0.2) : null,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${slot.name.toUpperCase()}: ${equippedItem?.name ?? "None"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Ithica',
                    fontSize: 20,
                  ),
                ),
              ),
              if (equippedItem != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      widget.player.addItem(equippedItem);
                      widget.player.unequip(slot);
                      widget.player.saveEquipment();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _hasCompatibleEquipment(slot)
                            ? Colors.white70
                            : Colors
                                .orangeAccent, // Highlight if no replacements
                  ),
                  child: const Text('Unequip'),
                ),

              TextButton(
                onPressed: () => _selectEquipmentForSlot(slot),
                child: const Text(
                  'Change',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasCompatibleEquipment(EquipmentSlot slot) {
    return widget.player.inventory.whereType<Equipment>().any(
      (e) => e.slot == slot,
    );
  }

  bool selectingEquipment = false;

  void _selectEquipmentForSlot(EquipmentSlot slot) {
    final matching =
        widget.player.inventory
            .whereType<Equipment>()
            .where((e) => e.slot == slot)
            .toList();

    if (matching.isEmpty) return;

    setState(() {
      selectingEquipment = true;
      _dialogEquipmentOptions = matching;
      selectedEquipmentDialogIndex = 0;
      _equipmentSelectionCompleter = Completer<Equipment?>();
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'Select Equipment',
                style: TextStyle(color: Colors.white, fontFamily: 'Ithica'),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: _dialogEquipmentOptions.length,
                  itemBuilder: (context, i) {
                    final item = _dialogEquipmentOptions[i];
                    final isSelected = i == selectedEquipmentDialogIndex;
                    return Container(
                      color: isSelected ? Colors.white24 : null,
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Ithica',
                          ),
                        ),
                        subtitle: Text(
                          'DMG: ${item.damage}, DEF: ${item.defense}, INT: ${item.intelligence}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Ithica',
                          ),
                        ),
                        onTap: () {
                          if (!_equipmentSelectionCompleter!.isCompleted) {
                            Navigator.pop(context);
                            _equipmentSelectionCompleter!.complete(
                              _dialogEquipmentOptions[i],
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      selectingEquipment = false;
      _dialogEquipmentOptions = [];
    });

    _equipmentSelectionCompleter!.future.then((selectedItem) {
      if (selectedItem != null) {
        setState(() {
          widget.player.equip(selectedItem);
          widget.player.removeItem(selectedItem);
          widget.player.saveEquipment();
        });
      }
    });
  }

  int selectedPartyStatsIndex = 0;
  final ScrollController _partyStatsScrollController = ScrollController();

  Widget _buildPartyStats() {
    final List<BattleCharacter> party = [
      widget.player,
      ...widget.player.currentParty.where((c) => c.name != widget.player.name),
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
            color: isSelected ? Colors.white.withOpacity(0.2) : null,
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.name} - Lvl ${member.stats.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Ithica',
                    fontSize: 22,
                  ),
                ),
                Text(
                  'HP: ${member.currentHP}/${member.stats.maxHp.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Ithica',
                  ),
                ),
                const Text(
                  'Attacks:',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Ithica'),
                ),
                ...member.attacks.map(
                  (a) => Text(
                    '- ${a.name} (${a.type.name}, ${a.power}x)',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontFamily: 'Ithica',
                    ),
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
      // case 3:
      // return _buildSettingsTab();
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
          // borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paused',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontFamily: '8-bit-limit',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Money: \$${widget.player.money}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontFamily: 'Ithica',
              ),
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
                      fontSize: 22,
                      fontFamily: 'Ithica',
                      color: selected ? Colors.white : Colors.white,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Expanded(child: SingleChildScrollView(child: _buildContent())),
            Expanded(child: _buildContent()),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
