import 'dart:convert';

import 'package:game/game/characters/party/PartyMember.dart';
import 'package:game/game/items/items.dart';
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

  List<PartyMember> currentParty = [];

  Future<void> loadParty() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('$name-party') ?? [];

    currentParty =
        jsonList.map((str) {
          final data = jsonDecode(str);
          return PartyMember.fromJson(data); // replace with factory if needed
        }).toList();
  }

  Future<void> saveParty() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = currentParty.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('$name-party', jsonList);
  }

  void addToParty(PartyMember member) {
    if (!currentParty.any((m) => m.name == member.name)) {
      currentParty.add(member);
      saveParty();
    }
  }

  void removeFromParty(String name) {
    currentParty.removeWhere((m) => m.name == name);
    saveParty();
  }

  void clearParty() {
    currentParty.clear();
    saveParty();
  }

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
