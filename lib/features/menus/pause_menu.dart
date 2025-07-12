import 'package:flutter/material.dart';

class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paused', style: TextStyle(fontSize: 24, color: Colors.white)),
            SizedBox(height: 12),
            Text('Press P to resume', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
