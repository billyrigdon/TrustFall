import 'dart:math';
import 'package:flutter/material.dart';
import 'package:game/features/characters/battle_character.dart';
import 'package:game/features/characters/enemies/test_enemy.dart';
import 'package:game/features/characters/main_player.dart';
import 'package:game/features/items/items.dart';
import 'package:game/services/attacks.dart';

class BattleManager extends ChangeNotifier {
  final List<BattleCharacter> party;
  final Enemy enemy;
  bool playerTurn = true;
  bool battleEnded = false;

  BattleManager({required this.party, required this.enemy}) {
    reset();
  }

  Future<void> restoreAllHP() async {
    for (final member in party) {
      member.currentHP = member.stats.maxHp.toInt();
      await member.saveHP();
    }
  }

  void reset() {
    // Don't reset HP to full — we now persist it
    playerTurn = true;
    battleEnded = false;
    notifyListeners();
  }

  void attackEnemy(BattleCharacter attacker, Attack attack) {
    if (!playerTurn || battleEnded || !attacker.isAlive) return;

    final base = attacker.stats.strength;
    final damage = (base * attack.power).round();

    enemy.takeDamage(damage);

    if (!enemy.isAlive) {
      battleEnded = true;

      for (final member in party) {
        if (member.isAlive) {
          member.gainXpFromEnemy(baseXp: 50, enemyLevel: enemy.level);
        }
      }
    } else {
      playerTurn = false;
      Future.delayed(const Duration(seconds: 1), enemyAttack);
    }

    notifyListeners();
  }

  void useItemOn(BattleCharacter target, Item item) {
    if (!playerTurn || battleEnded || !target.isAlive) return;

    switch (item.type) {
      case ItemType.health:
        target.heal(20); // or read from a field like `item.power`
        break;
      default:
        // You can extend this logic to support buffs/equipment/etc.
        break;
    }

    // Remove from whoever used it
    final user = party.firstWhere((c) => c.inventory.contains(item));
    user.removeItem(item);

    playerTurn = false;
    Future.delayed(const Duration(seconds: 1), enemyAttack);
    notifyListeners();
  }

  void enemyAttack() {
    final aliveTargets = party.where((c) => c.isAlive).toList();
    if (aliveTargets.isEmpty) {
      battleEnded = true;
      restoreAllHP();
      notifyListeners();
      return;
    }

    final target = aliveTargets[Random().nextInt(aliveTargets.length)];
    final attack = enemy.attacks[Random().nextInt(enemy.attacks.length)];
    final damage = (enemy.stats.strength * attack.power).round();

    target.takeDamage(damage);

    if (party.every((c) => !c.isAlive)) {
      battleEnded = true;
    } else {
      playerTurn = true;
    }

    notifyListeners();
  }
}
