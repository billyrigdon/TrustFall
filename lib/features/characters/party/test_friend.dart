// import 'package:flame/components.dart';
// import 'package:game/features/characters/battle_character.dart';
// import 'package:game/features/items/items.dart';
// import 'package:game/main.dart';
// import 'package:game/services/attacks.dart';
// // import 'package:game/models/battle_character.dart';
// // import 'package:game/models/character_stats.dart';
// import 'package:game/services/character_stats.dart';

// class TestPartyMember extends SpriteAnimationComponent
//     with HasGameRef<TrustFall>
//     implements BattleCharacter {
//   @override
//   final String name;
//   @override
//   List<Item> inventory = [];

//   @override
//   CharacterStats stats;

//   @override
//   int currentHP;

//   TestPartyMember({required this.name, required this.stats})
//     : currentHP = stats.maxHp.toInt(),
//       super(size: Vector2(48, 80), anchor: Anchor.topLeft);

//   @override
//   Future<void> onLoad() async {
//     animation = SpriteAnimation.spriteList([
//       await gameRef.loadSprite('sprite.png'),
//     ], stepTime: 1.0);

//     attacks = [
//       Attack(name: 'Slash', type: AttackType.normal, power: 1.0),
//       Attack(name: 'Inspire', type: AttackType.fire, power: 1.2),
//     ];
//   }

//   @override
//   bool get isAlive => currentHP > 0;

//   @override
//   void takeDamage(int damage) {
//     currentHP = (currentHP - damage).clamp(0, stats.maxHp.toInt());
//   }

//   @override
//   void heal(int amount) {
//     currentHP = (currentHP + amount).clamp(0, stats.maxHp.toInt());
//   }

//   @override
//   late List<Attack> attacks;

//   @override
//   void gainXpFromEnemy({required double baseXp, required int enemyLevel}) {
//     // TODO: implement gainXpFromEnemy
//   }

//   @override
//   set name(String _name) {
//     // TODO: implement name
//   }

//   @override
//   void addItem(Item item) {
//     // TODO: implement addItem
//   }

//   @override
//   void learnAttack(Attack attack) {
//     // TODO: implement learnAttack
//   }

//   @override
//   Future<void> loadAttacks() {
//     // TODO: implement loadAttacks
//     throw UnimplementedError();
//   }

//   @override
//   Future<void> loadHP() {
//     // TODO: implement loadHP
//     throw UnimplementedError();
//   }

//   @override
//   void removeItem(Item item) {
//     // TODO: implement removeItem
//   }

//   @override
//   Future<void> saveAttacks() {
//     // TODO: implement saveAttacks
//     throw UnimplementedError();
//   }

//   @override
//   Future<void> saveHP() {
//     // TODO: implement saveHP
//     throw UnimplementedError();
//   }
// }
import 'dart:convert';
import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game/features/characters/battle_character.dart';
import 'package:game/features/items/items.dart';
import 'package:game/services/attacks.dart';
import 'package:game/services/character_stats.dart';

class TestPartyMember extends SpriteComponent implements BattleCharacter {
  @override
  late String name;

  @override
  late CharacterStats stats;

  @override
  int currentHP = 0;

  @override
  List<Item> inventory = [];

  @override
  List<Attack> attacks = [];

  TestPartyMember({required this.name, required CharacterClass charClass}) {
    _init(charClass);
  }

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
    Attack(name: 'Slash', type: AttackType.normal, power: 1.0),
    Attack(name: 'Inspire', type: AttackType.fire, power: 1.2),
  ];
}
