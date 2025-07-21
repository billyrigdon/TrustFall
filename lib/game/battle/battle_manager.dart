import 'dart:math';
import 'package:flutter/material.dart';
import 'package:game/game/battle/battle_action.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/battle_status.dart';
import 'package:game/models/enemy.dart';
import 'package:game/models/items.dart';
import 'package:game/models/attacks.dart';

class BattleManager extends ChangeNotifier {
  final List<BattleCharacter> party;
  final Enemy enemy;
  bool playerTurn = true;
  bool battleEnded = false;
  final List<BattleAction> pendingActions = [];

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
    playerTurn = true;
    battleEnded = false;
    notifyListeners();
  }

  Future<void> attackEnemy(
    BattleCharacter attacker,
    Attack attack,
    Future<void> Function(String message, {bool requireConfirmation})
    showMessage,
  ) async {
    if (!playerTurn || battleEnded || !attacker.isAlive) return;

    final didHit = Random().nextDouble() <= attack.accuracy;
    if (!didHit) {
      await showMessage('${attacker.name} used ${attack.name} but it missed!');
      return;
    }

    final base = attacker.totalDamage;
    final damage = ((base * attack.power)).round();

    enemy.takeDamage(damage);
    await showMessage(
      '${attacker.name} used ${attack.name} and dealt $damage!',
    );

    if (attack.statusEffect != null && attack.statusDuration != null) {
      final randomMultiplier =
          1 +
          (Random().nextDouble() * attack.statusDurationVariance * 2 -
              attack.statusDurationVariance);

      final randomizedDuration = (attack.statusDuration! * randomMultiplier)
          .round()
          .clamp(1, 10);

      enemy.applyStatus(
        BattleStatus(type: attack.statusEffect!, duration: randomizedDuration),
      );
      await showMessage(
        '${enemy.name} is now ${attack.statusEffect.toString().split('.').last}!',
      );
    }

    if (!enemy.isAlive) {
      for (final member in party) {
        if (member.isAlive) {
          final xp = 50.0;
          member.gainXpFromEnemy(baseXp: xp, enemyLevel: enemy.level);
          await showMessage(
            '${member.name} gained $xp XP!',
            requireConfirmation: true,
          );
        }
      }
      await showMessage('You won!', requireConfirmation: true);
      battleEnded = true;
    }

    notifyListeners();
  }

  Future<void> mentallyAttackEnemy(
    BattleCharacter attacker,
    Attack attack,
    Future<void> Function(String message, {bool requireConfirmation})
    showMessage,
  ) async {
    if (!playerTurn || battleEnded || !attacker.isAlive) return;

    final didHit = Random().nextDouble() <= attack.accuracy;
    if (!didHit) {
      await showMessage('${attacker.name} used ${attack.name} but it missed!');
      return;
    }

    final base = attacker.totalIntelligence;
    final damage = (base * attack.power).round();

    attacker.currentMP -= attack.cost!;

    enemy.takeDamage(damage);
    await showMessage(
      '${attacker.name} used ${attack.name} and dealt $damage!',
    );

    if (attack.statusEffect != null && attack.statusDuration != null) {
      final randomMultiplier =
          1 +
          (Random().nextDouble() * attack.statusDurationVariance * 2 -
              attack.statusDurationVariance);
      // example: 1 ± 0.5 = range of 0.5 to 1.5

      final randomizedDuration = (attack.statusDuration! * randomMultiplier)
          .round()
          .clamp(1, 10);

      enemy.applyStatus(
        BattleStatus(type: attack.statusEffect!, duration: randomizedDuration),
      );
      await showMessage(
        '${enemy.name} is now ${attack.statusEffect.toString().split('.').last}!',
      );
    }

    if (!enemy.isAlive) {
      for (final member in party) {
        if (member.isAlive) {
          final xp = 50.0;
          member.gainXpFromEnemy(baseXp: xp, enemyLevel: enemy.level);
          await showMessage(
            '${member.name} gained $xp XP!',
            requireConfirmation: true,
          );
        }
      }
      await showMessage('You won!', requireConfirmation: true);
      battleEnded = true;
    }

    notifyListeners();
  }

  Future<void> enemyAttack(
    Future<void> Function(String message, {bool requireConfirmation})
    showMessage,
  ) async {
    final aliveTargets = party.where((c) => c.isAlive).toList();
    if (aliveTargets.isEmpty) {
      await showMessage("Everyone has fainted...", requireConfirmation: true);
      await _endBattleLoss(showMessage);
      return;
    }

    final target = aliveTargets[Random().nextInt(aliveTargets.length)];
    final attack = enemy.attacks[Random().nextInt(enemy.attacks.length)];
    final damage = (enemy.stats.strength * attack.power).round();

    final didHit = Random().nextDouble() <= attack.accuracy;
    if (!didHit) {
      await showMessage('${enemy.name} used ${attack.name} but it missed!');
      return;
    }

    target.takeDamage(damage);
    await showMessage('${enemy.name} used ${attack.name} and dealt $damage!');

    // ⬇️ Handle status effect
    if (attack.statusEffect != null && attack.statusDuration != null) {
      final variance = attack.statusDurationVariance;
      final multiplier = 1 + (Random().nextDouble() * variance * 2 - variance);
      final randomizedDuration = (attack.statusDuration! * multiplier)
          .round()
          .clamp(1, 10);

      target.applyStatus(
        BattleStatus(type: attack.statusEffect!, duration: randomizedDuration),
      );

      await showMessage(
        '${target.name} is now ${attack.statusEffect.toString().split('.').last}!',
      );
    }

    if (party.every((c) => !c.isAlive)) {
      await showMessage('You lost!', requireConfirmation: true);
      await _endBattleLoss(showMessage);
    } else {
      playerTurn = true;
    }

    notifyListeners();
  }

  Future<void> _endBattleLoss(Future<void> Function(String) showMessage) async {
    battleEnded = true;
    await restoreAllHP(); // optional, or keep this for debugging
    notifyListeners(); // trigger rebuild for `battleEnded` check
  }

  Future<void> useItemOn(
    BattleCharacter target,
    Item item,
    Future<void> Function(String message, {bool requireConfirmation})
    showMessage,
  ) async {
    if (!playerTurn || battleEnded || !target.isAlive) return;

    final user = party.firstWhere((c) => c.inventory.contains(item));

    switch (item.type) {
      case ItemType.food:
        target.heal(item.value ?? 0);
        await showMessage(
          '${user.name} used ${item.name} and healed ${item.value ?? 0} HP!',
        );
        break;
      default:
        await showMessage('${user.name} used ${item.name}.');
        break;
    }

    user.removeItem(item);

    notifyListeners();
  }

  Future<void> throwItem(
    BattleCharacter actor,
    Item item,
    Future<void> Function(String message, {bool requireConfirmation})
    showMessage,
  ) async {
    if (!playerTurn || battleEnded || !actor.isAlive) return;

    final damage = item.damage;
    enemy.takeDamage(damage.toInt());

    await showMessage('${actor.name} threw ${item.name} and dealt $damage!');

    actor.removeItem(item);

    if (!enemy.isAlive) {
      for (final member in party) {
        if (member.isAlive) {
          final xp = 50.0;
          member.gainXpFromEnemy(baseXp: xp, enemyLevel: enemy.level);
          await showMessage(
            '${member.name} gained $xp XP!',
            requireConfirmation: true,
          );
        }
      }

      await showMessage('You won!', requireConfirmation: true);
      battleEnded = true;
    }
  }
}
