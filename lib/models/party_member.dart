import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game/models/battle_status.dart';
import 'package:game/models/can_act_result.dart';
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
    required this.bank,
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

  final List<BattleStatus> statuses = [];

  bool hasStatus(BattleStatusType type) {
    return statuses.any((s) => s.type == type && s.duration > 0);
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
  List<PartyMember> currentParty = [];

  Future<void> _init(CharacterClass charClass) async {
    sprite = await Sprite.load('sprite.png');
    stats = await CharacterStats.load(name, charClass);

    await loadHP();
    await loadAttacks();
    await loadBank();
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
    stats.saveStats(name);
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
      bank:
          (json['bank'] as List<dynamic>)
              .map((a) => Attack.fromJson(Map<String, dynamic>.from(a)))
              .toList(),
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
      'bank': bank.map((a) => a.toJson()).toList(),
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

  @override
  int currentMP = 0;

  @override
  List<Attack> bank;

  @override
  void learnBankMove(Attack attack) {
    // TODO: implement learnBankMove
    if (!bank.any((a) => a.name == attack.name)) {
      bank.add(attack);
      saveBank();
    }
  }

  @override
  Future<void> loadBank() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$name-bank-moves');

    if (raw == null || raw.isEmpty) {
      bank = _defaultBank();
      await saveBank();
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
  Future<void> saveBank() async {
    final prefs = await SharedPreferences.getInstance();
    final data = attacks.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('$name-attacks', data);
  }

  List<Attack> _defaultBank() => [
    Attack(name: 'Insult', type: AttackType.mental, cost: 10, power: 1.0),
  ];
}
