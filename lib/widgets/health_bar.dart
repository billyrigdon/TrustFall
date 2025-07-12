import 'package:flutter/material.dart';

class HealthBar extends StatelessWidget {
  final String label;
  final int hp;

  const HealthBar({super.key, required this.label, required this.hp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$label: $hp/100',
          style: const TextStyle(color: Colors.white),
        ),
        Container(
          width: 200,
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            color: Colors.grey.shade800,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: hp / 100,
            child: Container(color: Colors.green),
          ),
        ),
      ],
    );
  }
}
