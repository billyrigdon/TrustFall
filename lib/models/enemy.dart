import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show BoxFit, Image, VoidCallback, Widget;
import 'package:game/models/battle_character.dart';
import 'package:game/models/battle_status.dart';
import 'package:game/models/can_act_result.dart';
import 'package:game/models/equipment.dart';
import 'package:game/models/party_member.dart';
import 'package:game/models/items.dart';
import 'package:game/models/attacks.dart';
import 'package:game/models/character_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<CanActResult> canAct(
    Future<void> Function(String message, {bool requireConfirmation})
    showMessage,
  ) async {
    bool canAct = true;
    bool forceRandomTarget = false;
    bool forceAttack = false;
    bool blockSelfSupport = false;

    for (final status in statuses.where((s) => s.duration > 0)) {
      switch (status.type) {
        case BattleStatusType.stunned:
        case BattleStatusType.asleep:
          await showMessage('$name is ${status.type.name} and can’t act!');
          return CanActResult(canAct: false);
        case BattleStatusType.confused:
          forceRandomTarget = true;
          await showMessage('$name is confused...');
          break;
        case BattleStatusType.rage:
          forceAttack = true;
          await showMessage('$name is in a rage and must attack!');
          break;
        case BattleStatusType.selfDoubt:
          blockSelfSupport = true;
          await showMessage('$name is full of doubt...');
          break;
        case BattleStatusType.embarrassed:
          // 25% chance to skip turn
          if (Random().nextDouble() < 0.25) {
            await showMessage('$name is too embarrassed to act...');
            return CanActResult(canAct: false);
          }
          break;
        case BattleStatusType.charmed:
          // 50% chance to skip attacking the enemy
          if (Random().nextDouble() < 0.5) {
            await showMessage('$name is charmed and refuses to attack!');
            return CanActResult(canAct: false);
          }
          break;
      }
    }

    return CanActResult(
      canAct: canAct,
      forceRandomTarget: forceRandomTarget,
      forceAttack: forceAttack,
      blockSelfSupport: blockSelfSupport,
    );
  }



final List<BattleStatus> statuses = [];

  bool hasStatus(BattleStatusType type) {
    return statuses.any((s) => s.type == type && s.duration > 0);
  }

  void applyStatus(BattleStatus status) {
    final existing = statuses.firstWhere(
      (s) => s.type == status.type,
      orElse: () => BattleStatus(type: status.type, duration: 0),
    );
    if (existing.duration == 0) {
      statuses.add(status);
    } else {
      existing.duration = max(existing.duration, status.duration);
    }
  }

  void decrementStatuses() {
    for (final s in statuses) {
      if (s.duration > 0) s.duration--;
    }
  }


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

final Map<EquipmentSlot, Equipment?> equipped = {
    for (var slot in EquipmentSlot.values) slot: null,
  };

  int get totalDefense {
    final gearBonus = equipped.values.whereType<Equipment>().fold<int>(
      0,
      (sum, eq) => sum + eq.defense,
    );
    return stats.defense.toInt() + gearBonus;
  }

  int get totalIntelligence {
    final gearBonus = equipped.values.whereType<Equipment>().fold<int>(
      0,
      (sum, eq) => sum + eq.intelligence,
    );
    return stats.intelligence.toInt() + gearBonus;
  }

  double get totalDamage {
    final weapon = equipped[EquipmentSlot.weapon];
    return (weapon?.damage ?? 0);
  }

  bool equip(Equipment item) {
    if (item.slot == null) return false;
    equipped[item.slot] = item;
    return true;
  }

  void unequip(EquipmentSlot slot) {
    equipped[slot] = null;
  }

  Future<void> saveEquipment() async {
    final prefs = await SharedPreferences.getInstance();
    final map = equipped.map(
      (slot, item) => MapEntry(
        slot.toString().split('.').last,
        item != null ? jsonEncode(item.toJson()) : '',
      ),
    );
    await prefs.setString('$name-equipment', jsonEncode(map));
  }

  Future<void> loadEquipment() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$name-equipment');
    if (raw == null) return;

    final Map<String, dynamic> jsonMap = jsonDecode(raw);
    for (final entry in jsonMap.entries) {
      final slot = equipmentSlotFromString(entry.key);
      final data = entry.value;
      equipped[slot] =
          data.isNotEmpty ? Equipment.fromJson(jsonDecode(data)) : null;
    }
  }

}
