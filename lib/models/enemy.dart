import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show BoxFit, Image, VoidCallback, Widget;
import 'package:game/models/battle_character.dart';
import 'package:game/models/party_member.dart';
import 'package:game/models/items.dart';
import 'package:game/models/attacks.dart';
import 'package:game/models/character_stats.dart';

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

  String spriteAsset;

  String characterId;

  Enemy({
    required this.characterId,
    required this.name,
    required this.level,
    required this.stats,
    required this.attacks,
    required this.spriteAsset,
    required this.bank,
    // required this.onInteract,
  }) : currentHP = stats.maxHp.toInt(),
       currentMP = stats.maxMP.toInt(),
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

  @override
  bool get isAlive => currentHP > 0;

  VoidCallback? onInteract;

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

  @override
  int currentMP;

  @override
  List<Attack> bank;

  @override
  void learnBankMove(Attack attack) {
    // TODO: implement learnBankMove
  }

  @override
  Future<void> loadBank() {
    // TODO: implement loadBank
    throw UnimplementedError();
  }

  @override
  Future<void> saveBank() {
    // TODO: implement saveBank
    throw UnimplementedError();
  }
}
