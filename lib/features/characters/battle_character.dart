// import 'package:game/services/attacks.dart';
// import 'package:game/services/character_stats.dart';

// abstract class BattleCharacter {
//   String name;
//   CharacterStats stats;
//   int currentHP;

//   BattleCharacter({required this.name, required this.stats})
//     : currentHP = stats.hp.toInt();

//   bool get isAlive => currentHP > 0;

//   void takeDamage(int damage) {
//     currentHP = (currentHP - damage).clamp(0, stats.hp.toInt());
//   }

//   void heal(int amount) {
//     currentHP = (currentHP + amount).clamp(0, stats.hp.toInt());
//   }

//   void gainXpFromEnemy({required double baseXp, required int enemyLevel}) {
//     final levelDiff = enemyLevel - stats.level;
//     final modifier = 1.0 + (levelDiff * 0.1);
//     stats.gainXP(baseXp * modifier.clamp(0.5, 2.0));
//   }

//   List<Attack> attacks = [
//     Attack(name: 'Basic Attack', type: AttackType.normal, power: 1.0),
//   ];
// }
import 'dart:convert';

import 'package:game/features/items/items.dart';
import 'package:game/services/attacks.dart';
import 'package:game/services/character_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BattleCharacter {
  late String name;
  late CharacterStats stats;

  int get currentHP => _currentHP;
  set currentHP(int hp) => _currentHP = hp;
  int _currentHP = 0;
  List<Item> inventory = [];
  List<Attack> attacks = [];

  void addItem(Item item) => inventory.add(item);
  void removeItem(Item item) => inventory.remove(item);

  Future<void> loadHP() async {
    final prefs = await SharedPreferences.getInstance();
    _currentHP = prefs.getInt('$name-hp') ?? stats.maxHp.toInt();
  }

  Future<void> saveHP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$name-hp', _currentHP);
  }

  void takeDamage(int damage) {
    _currentHP = (_currentHP - damage).clamp(0, stats.maxHp.toInt());
    saveHP();
  }

  void heal(int amount) {
    _currentHP = (_currentHP + amount).clamp(0, stats.maxHp.toInt());
    saveHP();
  }

  void gainXpFromEnemy({required double baseXp, required int enemyLevel}) {
    final levelDiff = enemyLevel - stats.level;
    final modifier = 1.0 + (levelDiff * 0.1);
    stats.gainXP(baseXp * modifier.clamp(0.5, 2.0), id: name);
  }

  Future<void> loadAttacks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('$name-attacks');

    if (saved == null || saved.isEmpty) {
      attacks = _defaultAttacks();
      await saveAttacks(); // ensure it's stored
    } else {
      attacks =
          saved
              .map(
                (str) =>
                    Attack.fromJson(Map<String, dynamic>.from(jsonDecode(str))),
              )
              .toList();
    }
  }

  Future<void> saveAttacks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = attacks.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('$name-attacks', list);
  }

  void learnAttack(Attack attack) {
    if (!attacks.any((a) => a.name == attack.name)) {
      attacks.add(attack);
      saveAttacks();
    }
  }

  List<Attack> _defaultAttacks(); // Must be implemented by subclasses

  bool get isAlive => _currentHP > 0;
}
