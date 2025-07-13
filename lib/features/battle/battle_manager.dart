import 'package:flutter/material.dart';
import 'package:game/features/characters/battle_character.dart';
import 'package:game/features/characters/enemies/test_enemy.dart';
import 'package:game/features/characters/main_player.dart';

// class BattleManager extends ChangeNotifier {
//   int playerHP = 100;
//   int enemyHP = 100;
//   bool playerTurn = true;
//   bool battleEnded = false;

//   void attackEnemy() {
//     if (!playerTurn || battleEnded) return;
//     enemyHP -= 20;
//     if (enemyHP <= 0) {
//       enemyHP = 0;
//       battleEnded = true;
//     } else {
//       playerTurn = false;
//       Future.delayed(const Duration(seconds: 1), enemyAttack);
//     }
//     notifyListeners();
//   }

//   void useItem(String item) {
//     if (!playerTurn || battleEnded) return;
//     if (item == 'Burger') {
//       playerHP = (playerHP + 20).clamp(0, 100);
//     } else if (item == 'Cola') {
//       playerHP = (playerHP + 10).clamp(0, 100);
//     }
//     playerTurn = false;
//     Future.delayed(const Duration(seconds: 1), enemyAttack);
//     notifyListeners();
//   }

//   void enemyAttack() {
//     playerHP -= 15;
//     if (playerHP <= 0) {
//       playerHP = 0;
//       battleEnded = true;
//     } else {
//       playerTurn = true;
//     }
//     notifyListeners();
//   }

//   void reset() {
//     playerHP = 100;
//     enemyHP = 100;
//     playerTurn = true;
//     battleEnded = false;
//     notifyListeners();
//   }
// }
class BattleManager extends ChangeNotifier {
  final List<BattleCharacter> party;
  final Enemy enemy;
  bool playerTurn = true;
  bool battleEnded = false;

  BattleManager({required this.party, required this.enemy}) {
    reset();
  }

  void reset() {
    for (final member in party) {
      member.currentHP = member.stats.hp.toInt();
    }
    enemy.currentHP = enemy.stats.hp.toInt();
    playerTurn = true;
    battleEnded = false;
    notifyListeners();
  }

  void attackEnemy(BattleCharacter attacker) {
    if (!playerTurn || battleEnded) return;
    final damage = attacker.stats.strength.toInt();
    enemy.takeDamage(damage);

    if (!enemy.isAlive) {
      battleEnded = true;
      for (final member in party) {
        if (member is MainPlayer) {
          member.gainXpFromEnemy(baseXp: 50, enemyLevel: enemy.level);
        }
      }
    } else {
      playerTurn = false;
      Future.delayed(const Duration(seconds: 1), enemyAttack);
    }
    notifyListeners();
  }

  void useItemOn(BattleCharacter target, String item) {
    if (!playerTurn || battleEnded) return;

    if (item == 'Burger') {
      target.heal(20);
    } else if (item == 'Cola') {
      target.heal(10);
    }

    playerTurn = false;
    Future.delayed(const Duration(seconds: 1), enemyAttack);
    notifyListeners();
  }

  void enemyAttack() {
    final target = party.firstWhere(
      (c) => c.isAlive,
      orElse: () => party.first,
    );
    target.takeDamage(15);
    if (!target.isAlive && party.every((c) => !c.isAlive)) {
      battleEnded = true;
    } else {
      playerTurn = true;
    }
    notifyListeners();
  }
}
