import 'dart:convert';
import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game/game/characters/battle_character.dart';
import 'package:game/game/items/items.dart';
import 'package:game/services/attacks.dart';
import 'package:game/services/character_stats.dart';

class PartyMember extends SpriteComponent implements BattleCharacter {
  @override
  late String name;

  @override
  late CharacterStats stats;

  CharacterClass charClass;

  @override
  int currentHP = 0;

  @override
  List<Item> inventory = [];

  @override
  List<Attack> attacks = [];

  PartyMember({required this.name, required this.charClass}) {
    stats = CharacterStats(charClass: charClass);
    _init(charClass);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'charClass': charClass.toString().split('.').last,
    'stats': stats.toJson(), // assumes stats has .toJson()
    'inventory': inventory.map((i) => i.toJson()).toList(),
    'attacks': attacks.map((a) => a.toJson()).toList(),
    'currentHP': currentHP,
  };

  static PartyMember fromJson(Map<String, dynamic> json) {
    CharacterClass characterClassFromString(String str) {
      return CharacterClass.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
        orElse: () => CharacterClass.balanced,
      );
    }

    final member = PartyMember(
      name: json['name'],
      charClass: characterClassFromString(json['charClass']),
    );
    member.stats = CharacterStats.fromJson(json['stats']);
    member.inventory =
        (json['inventory'] as List)
            .map(
              (i) =>
                  i['slot'] != null ? Equipment.fromJson(i) : Item.fromJson(i),
            )
            .toList();
    member.attacks =
        (json['attacks'] as List).map((a) => Attack.fromJson(a)).toList();
    member.currentHP = json['currentHP'];
    return member;
  }

  @override
  List<PartyMember> currentParty = [];

  Future<void> _init(CharacterClass charClass) async {
    sprite = await Sprite.load('sprite.png');
    stats = await CharacterStats.load(name, charClass);

    await loadHP();
    await loadAttacks();
  }

  @override
  Future<void> loadHP() async {
    final prefs = await SharedPreferences.getInstance();
    currentHP = prefs.getInt('$name-hp') ?? stats.maxHp.toInt();
  }

  @override
  Future<void> saveHP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$name-hp', currentHP);
  }

  @override
  void takeDamage(int damage) {
    currentHP = (currentHP - damage).clamp(0, stats.maxHp.toInt());
    saveHP();
  }

  @override
  void heal(int amount) {
    currentHP = (currentHP + amount).clamp(0, stats.maxHp.toInt());
    saveHP();
  }

  @override
  bool get isAlive => currentHP > 0;

  @override
  void gainXpFromEnemy({required double baseXp, required int enemyLevel}) {
    final levelDiff = enemyLevel - stats.level;
    final modifier = 1.0 + (levelDiff * 0.1);
    stats.gainXP(baseXp * modifier.clamp(0.5, 2.0), id: name);
  }

  @override
  void addItem(Item item) {
    // inventory.add(item);
  }

  @override
  void removeItem(Item item) {
    // inventory.removeWhere((i) => i.name == item.name);
  }

  @override
  void learnAttack(Attack attack) {
    if (!attacks.any((a) => a.name == attack.name)) {
      attacks.add(attack);
      saveAttacks();
    }
  }

  @override
  Future<void> loadAttacks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$name-attacks');

    if (raw == null || raw.isEmpty) {
      attacks = _defaultAttacks();
      await saveAttacks();
    } else {
      attacks =
          raw
              .map(
                (str) =>
                    Attack.fromJson(Map<String, dynamic>.from(jsonDecode(str))),
              )
              .toList();
    }
  }

  @override
  Future<void> saveAttacks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = attacks.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('$name-attacks', data);
  }

  List<Attack> _defaultAttacks() => [
    Attack(name: 'Kick', type: AttackType.physical, power: 1.0),
  ];

  @override
  void clearParty() {
    // TODO: implement clearParty
  }

  @override
  Future<void> loadParty() {
    // TODO: implement loadParty
    throw UnimplementedError();
  }

  @override
  void removeFromParty(String partyMemberName) {
    // TODO: implement removeFromParty
  }

  @override
  Future<void> saveParty() {
    // TODO: implement saveParty
    throw UnimplementedError();
  }

  @override
  void addToParty(BattleCharacter member) {
    // TODO: implement addToParty
  }
}
