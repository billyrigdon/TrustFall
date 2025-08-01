import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum CharacterClass {
  balanced,
  manipulator,
  actor,
  therapist,
  skeptic,
  snitch,
  pacifist,
}

class CharacterStats {
  int level;
  double xp;
  double xpToNext;
  double maxHp;
  double maxMP;
  double reputation;
  double confidence;
  double empathy;
  double strength;
  double defense;
  double speed;
  double intelligence;

  final CharacterClass charClass;
  final double levelMultiplier;

  CharacterStats({
    this.level = 1,
    this.xp = 0,
    this.xpToNext = 100,
    this.reputation = 0,
    this.empathy = 10,
    this.confidence = 10,
    this.strength = 10,
    this.defense = 10,
    this.maxHp = 50,
    this.maxMP = 50,
    this.speed = 10,
    this.intelligence = 10,
    required this.charClass,
    this.levelMultiplier = 1.0,
  });

  Future<void> loadStats(String id) async {
    final prefs = await SharedPreferences.getInstance();
    level = prefs.getInt('$id-level') ?? 1;
    xp = prefs.getDouble('$id-xp') ?? 0;
    xpToNext = prefs.getDouble('$id-xpToNext') ?? 100;
  }

  Future<void> saveStats(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$id-level', level);
    await prefs.setDouble('$id-xp', xp);
    await prefs.setDouble('$id-xpToNext', xpToNext);
  }

  Future<void> save(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(toJson());
    await prefs.setString('$id-stats', jsonStr);
  }

  static Future<CharacterStats> load(
    String id,
    CharacterClass defaultClass,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$id-stats');

    if (jsonStr != null) {
      final map = jsonDecode(jsonStr);
      return CharacterStats.fromJson(Map<String, dynamic>.from(map));
    } else {
      return CharacterStats(charClass: defaultClass);
    }
  }

  void gainXP(double amount, {required String id}) {
    xp += amount * levelMultiplier;
    while (xp >= xpToNext) {
      xp -= xpToNext;
      levelUp();
    }
    save(id);
  }

  void levelUp() {
    level++;
    xpToNext *= 1.2;

    final growth = _getGrowthRates();
    confidence += growth['confidence']!;
    strength += growth['strength']!;
    defense += growth['defense']!;
    maxHp += growth['hp']!;
    maxMP += growth['mp']!;
    speed += growth['speed']!;
    intelligence += growth['intelligence']!;
    empathy += growth['empathy']!;
    reputation += growth['reputation']!;
  }

  Map<String, double> _getGrowthRates() {
    switch (charClass) {
      case CharacterClass.manipulator:
        return {
          'confidence': 3,
          'strength': 1,
          'defense': 1,
          'hp': 3,
          'mp': 6,
          'speed': 3,
          'intelligence': 5,
          'empathy': 1,
          'reputation': 2,
        };
      case CharacterClass.actor:
        return {
          'confidence': 4,
          'strength': 2,
          'defense': 1,
          'hp': 3,
          'mp': 5,
          'speed': 3,
          'intelligence': 3,
          'empathy': 2,
          'reputation': 3,
        };
      case CharacterClass.therapist:
        return {
          'confidence': 4,
          'strength': 1,
          'defense': 3,
          'hp': 4,
          'mp': 4,
          'speed': 2,
          'intelligence': 3,
          'empathy': 4,
          'reputation': 2,
        };
      case CharacterClass.skeptic:
        return {
          'confidence': 5,
          'strength': 2,
          'defense': 4,
          'hp': 5,
          'mp': 2,
          'speed': 2,
          'intelligence': 2,
          'empathy': 1,
          'reputation': 1,
        };
      case CharacterClass.snitch:
        return {
          'confidence': 1,
          'strength': 1,
          'defense': 1,
          'hp': 2,
          'mp': 5,
          'speed': 5,
          'intelligence': 4,
          'empathy': 2,
          'reputation': 4,
        };
      case CharacterClass.pacifist:
        return {
          'confidence': 5,
          'strength': 0,
          'defense': 3,
          'hp': 4,
          'mp': 5,
          'speed': 2,
          'intelligence': 3,
          'empathy': 5,
          'reputation': 3,
        };
      case CharacterClass.balanced:
        return {
          'confidence': 2,
          'strength': 2,
          'defense': 2,
          'hp': 4,
          'mp': 4,
          'speed': 2,
          'intelligence': 2,
          'empathy': 1,
          'reputation': 1,
        };
    }
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'xp': xp,
    'xpToNext': xpToNext,
    'confidence': confidence,
    'strength': strength,
    'empathy': empathy,
    'reputation': reputation,
    'defense': defense,
    'maxHp': maxHp,
    'maxMP': maxMP,
    'speed': speed,
    'intelligence': intelligence,
    'charClass': charClass.toString().split('.').last,
    'levelMultiplier': levelMultiplier,
  };

  static CharacterStats fromJson(Map<String, dynamic> json) {
    return CharacterStats(
      level: (json['level'] ?? 1).toInt(),
      xp: (json['xp'] ?? 0).toDouble(),
      xpToNext: (json['xpToNext'] ?? 100).toDouble(),
      confidence: (json['confidence'] ?? 10).toDouble(),
      strength: (json['strength'] ?? 10).toDouble(),
      defense: (json['defense'] ?? 10).toDouble(),
      maxHp: (json['maxHp'] ?? 100).toDouble(),
      maxMP: (json['maxMP'] ?? 100).toDouble(),
      speed: (json['speed'] ?? 10).toDouble(),
      empathy: (json['empathy'] ?? 10).toDouble(),
      reputation: (json['reputation'] ?? 10).toDouble(),
      intelligence: (json['intelligence'] ?? 10).toDouble(),
      charClass: CharacterClass.values.firstWhere(
        (e) => e.toString().split('.').last == json['charClass'],
        orElse: () => CharacterClass.balanced,
      ),
      levelMultiplier: (json['levelMultiplier'] ?? 1.0).toDouble(),
    );
  }
}
