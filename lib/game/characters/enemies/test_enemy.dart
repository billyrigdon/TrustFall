import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Image, Widget;
import 'package:game/game/characters/battle_character.dart';
import 'package:game/game/characters/party/PartyMember.dart';
import 'package:game/game/items/items.dart';
import 'package:game/services/attacks.dart';
import 'package:game/services/character_stats.dart';

class Enemy extends SpriteComponent with HasGameRef implements BattleCharacter {
  @override
  String name;

  @override
  CharacterStats stats;

  @override
  int currentHP;

  @override
  List<Attack> attacks;

  final int level;

  Enemy({
    required this.name,
    required this.level,
    required this.stats,
    required this.attacks,
  }) : currentHP = stats.maxHp.toInt(),
       super(size: Vector2(64, 64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('sprite.png');
  }

  Widget get imageWidget =>
      Image.asset('assets/images/sprite.png', width: 64, height: 64);

  @override
  bool get isAlive => currentHP > 0;

  @override
  void takeDamage(int damage) {
    currentHP = (currentHP - damage).clamp(0, stats.maxHp.toInt());
  }

  @override
  void heal(int amount) {
    currentHP = (currentHP + amount).clamp(0, stats.maxHp.toInt());
  }

  @override
  void gainXpFromEnemy({required double baseXp, required int enemyLevel}) {
    // Enemies do not gain XP or level
  }

  @override
  void addItem(Item item) {
    // Enemies don't carry items in this implementation
  }

  @override
  void removeItem(Item item) {
    // Enemies don't carry items
  }

  @override
  void learnAttack(Attack attack) {
    // Enemies don’t dynamically learn new attacks
  }

  @override
  Future<void> loadAttacks() async {
    // No-op for enemies
  }

  @override
  Future<void> saveAttacks() async {
    // No-op for enemies
  }

  @override
  Future<void> loadHP() async {
    // No-op for enemies
  }

  @override
  Future<void> saveHP() async {
    // No-op for enemies
  }

  @override
  List<Item> inventory = [];

  @override
  List<PartyMember> currentParty = [];

  @override
  void addToParty(PartyMember partyMemberName) {
    // TODO: implement addToParty
  }

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
}
