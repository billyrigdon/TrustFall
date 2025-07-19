import 'package:flutter/material.dart';

class MentalPowerBar extends StatelessWidget {
  // final String label;
  final int mp;
  final int maxMP;
  final bool isActive;

  const MentalPowerBar({
    super.key,
    // required this.label,
    required this.mp,
    required this.maxMP,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final mentalPercent = (mp / maxMP).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                widthFactor: mentalPercent,
                child: Container(color: Colors.blue),
              ),
            ),
            // Positioned(
            // right: 4,
            // bottom: -18,
            // child:
            Text(
              '$mp/$maxMP',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: '8-bit-limit',
              ),
            ),
            // ),
          ],
        ),
      ],
    );
  }
}
