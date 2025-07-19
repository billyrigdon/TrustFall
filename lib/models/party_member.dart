import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game/models/equipment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/items.dart';
import 'package:game/models/attacks.dart';
import 'package:game/models/character_stats.dart';

class PartyMember extends SpriteComponent
    with HasGameRef
    implements BattleCharacter {
  @override
  late String name;

  @override
  late CharacterStats stats;

  // CharacterClass charClass;

  @override
  int currentHP = 0;

  @override
  List<Item> inventory = [];

  @override
  List<Attack> attacks = [];

  // @override
  int level;

  String spriteAsset;

  String characterId;

  VoidCallback? onInteract;

  PartyMember({
    required this.characterId,
    required this.name,
    required this.level,
    required this.stats,
    required this.attacks,
    required this.spriteAsset,
    this.onInteract,
  }) : currentHP = stats.maxHp.toInt(),
       super(size: Vector2(30, 60), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    // debugMode = true;
    sprite = await gameRef.loadSprite(spriteAsset);
    print('rendered and loaded');
  }

  Widget get imageWidget => Image.asset(
    'assets/images/$spriteAsset',
    // scale: -10,
    fit: BoxFit.contain,
    width: Platform.isAndroid ? 64 : 256,
    height: Platform.isAndroid ? 64 : 256,
  );

  // PartyMember({required this.name, required this.charClass}) {
  //   stats = CharacterStats(charClass: charClass);
  //   _init(charClass);
  // }

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

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      characterId: json['characterId'],
      name: json['name'],
      level: json['level'],
      stats: CharacterStats.fromJson(Map<String, dynamic>.from(json['stats'])),
      attacks:
          (json['attacks'] as List<dynamic>)
              .map((a) => Attack.fromJson(Map<String, dynamic>.from(a)))
              .toList(),
      spriteAsset: json['spriteAsset'],
    )..currentHP = json['currentHP'];
  }

  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'name': name,
      'level': level,
      'currentHP': currentHP,
      'stats': stats.toJson(),
      'attacks': attacks.map((a) => a.toJson()).toList(),
      'spriteAsset': spriteAsset,
    };
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
