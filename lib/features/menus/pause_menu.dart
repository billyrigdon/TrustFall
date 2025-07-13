// import 'package:flutter/material.dart';

// class PauseMenu extends StatelessWidget {
//   const PauseMenu({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Container(
//         width: 220,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.85),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.white),
//         ),
//         child: const Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Paused', style: TextStyle(fontSize: 24, color: Colors.white)),
//             SizedBox(height: 12),
//             Text('Press P to resume', style: TextStyle(color: Colors.white70)),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:game/features/characters/main_player.dart';
import 'package:game/features/items/items.dart';
// import 'package:game/models/item.dart';

class PauseMenu extends StatefulWidget {
  final MainPlayer player;
  // final VoidCallback onResume;

  const PauseMenu({super.key, required this.player});

  @override
  State<PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<PauseMenu> {
  int selectedTab = 0;

  final List<String> tabs = ['Inventory', 'Equipment', 'Party'];

  void _useItem(Item item) {
    if (item.type == ItemType.health) {
      widget.player.heal(item.value ?? 0);
      setState(() {
        widget.player.removeItem(item);
      });
    }
    // Future: Handle other item types
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
            return Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.name} (${item.type.name})',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.player.name} - Lvl ${widget.player.stats.level}',
          style: const TextStyle(color: Colors.white),
        ),
        Text(
          'HP: ${widget.player.currentHP}/${widget.player.stats.maxHp.toInt()}',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text('Attacks:', style: TextStyle(color: Colors.white)),
        ...widget.player.attacks.map(
          (a) => Text(
            '- ${a.name} (${a.type.name}, ${a.power}x)',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
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
        width: 300,
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
            _buildContent(),
            const SizedBox(height: 24),
            // TextButton(
            //   onPressed: widget.onResume,
            //   child: const Text(
            //     'Resume',
            //     style: TextStyle(color: Colors.amber, fontSize: 16),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
