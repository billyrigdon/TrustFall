import 'package:flutter/material.dart';

class HealthBar extends StatelessWidget {
  final String label;
  final int hp;
  final int maxHp;
  final bool isActive;

  const HealthBar({
    super.key,
    required this.label,
    required this.hp,
    required this.maxHp,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final healthPercent = (hp / maxHp).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontFamily: '8-bit-limit',
            decoration: isActive ? TextDecoration.underline : null,
          ),
        ),

        Stack(
          children: [
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
            Text(
              '$hp/$maxHp',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: '8-bit-limit',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
