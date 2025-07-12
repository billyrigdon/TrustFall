import 'package:flutter/material.dart';

class TrustFallTextBox extends StatelessWidget {
  const TrustFallTextBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        child: const Text(
          "Hello! This is a textbox.",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
