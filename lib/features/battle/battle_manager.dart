import 'package:flutter/material.dart';

class BattleManager extends ChangeNotifier {
  int playerHP = 100;
  int enemyHP = 100;
  bool playerTurn = true;
  bool battleEnded = false;

  void attackEnemy() {
    if (!playerTurn || battleEnded) return;
    enemyHP -= 20;
    if (enemyHP <= 0) {
      enemyHP = 0;
      battleEnded = true;
    } else {
      playerTurn = false;
      Future.delayed(const Duration(seconds: 1), enemyAttack);
    }
    notifyListeners();
  }

  void useItem(String item) {
    if (!playerTurn || battleEnded) return;
    if (item == 'Burger') {
      playerHP = (playerHP + 20).clamp(0, 100);
    } else if (item == 'Cola') {
      playerHP = (playerHP + 10).clamp(0, 100);
    }
    playerTurn = false;
    Future.delayed(const Duration(seconds: 1), enemyAttack);
    notifyListeners();
  }

  void enemyAttack() {
    playerHP -= 15;
    if (playerHP <= 0) {
      playerHP = 0;
      battleEnded = true;
    } else {
      playerTurn = true;
    }
    notifyListeners();
  }

  void reset() {
    playerHP = 100;
    enemyHP = 100;
    playerTurn = true;
    battleEnded = false;
    notifyListeners();
  }
}
