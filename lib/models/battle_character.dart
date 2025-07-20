import 'dart:convert';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:game/models/battle_status.dart';
import 'package:game/models/can_act_result.dart';
import 'package:game/models/party_member.dart';
import 'package:game/models/items.dart';
import 'package:game/models/attacks.dart';
import 'package:game/models/character_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BattleCharacter extends SpriteComponent {
  late String name;
  late CharacterStats stats;

  int get currentHP => _currentHP;
  set currentHP(int hp) => _currentHP = hp;
  int _currentHP = 0;
  int get currentMP => _currentMP;
  set currentMP(int mp) => _currentMP = mp;
  int _currentMP = 0;
  List<Item> inventory = [];
  List<Attack> attacks = [];
  List<Attack> bank = [];

  List<PartyMember> currentParty = [];

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



  void decrementStatuses() {
    for (final s in statuses) {
      if (s.duration > 0) s.duration--;
    }
  }


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

  Future<void> loadBank() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('$name-bank-moves');

    if (saved == null || saved.isEmpty) {
      attacks = _defaultBank();
      await saveBank(); // ensure it's stored
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

Future<void> saveBank() async {
    final prefs = await SharedPreferences.getInstance();
    final list = attacks.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('$name-bank-moves', list);
  }

  void learnBankMove(Attack attack) {
    if (!bank.any((a) => a.name == attack.name)) {
      bank.add(attack);
      saveBank();
    }
  }


  List<Attack> _defaultAttacks(); // Must be implemented by subclasses

  List<Attack> _defaultBank(); 

  bool get isAlive => _currentHP > 0;
}
