import 'package:flutter/material.dart';

class HealthBar extends StatelessWidget {
  final String label;
  final int hp;
  final int maxHp;

  const HealthBar({
    super.key,
    required this.label,
    required this.hp,
    required this.maxHp,
  });

  @override
  Widget build(BuildContext context) {
    final healthPercent = (hp / maxHp).clamp(0.0, 1.0);

    return Column(
      children: [
        Text('$label: $hp/$maxHp', style: const TextStyle(color: Colors.white)),
        Container(
          width: 200,
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            color: Colors.grey.shade800,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: healthPercent,
            child: Container(color: Colors.green),
          ),
        ),
      ],
    );
  }
}
