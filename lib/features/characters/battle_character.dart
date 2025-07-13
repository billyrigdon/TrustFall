import 'package:game/services/attacks.dart';
import 'package:game/services/character_stats.dart';

abstract class BattleCharacter {
  String name;
  CharacterStats stats;
  int currentHP;

  BattleCharacter({required this.name, required this.stats})
    : currentHP = stats.hp.toInt();

  bool get isAlive => currentHP > 0;

  void takeDamage(int damage) {
    currentHP = (currentHP - damage).clamp(0, stats.hp.toInt());
  }

  void heal(int amount) {
    currentHP = (currentHP + amount).clamp(0, stats.hp.toInt());
  }

  void gainXpFromEnemy({required double baseXp, required int enemyLevel}) {
    final levelDiff = enemyLevel - stats.level;
    final modifier = 1.0 + (levelDiff * 0.1);
    stats.gainXP(baseXp * modifier.clamp(0.5, 2.0));
  }

  List<Attack> attacks = [
    Attack(name: 'Basic Attack', type: AttackType.normal, power: 1.0),
  ];
}
