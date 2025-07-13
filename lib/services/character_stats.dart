import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum CharacterClass { balanced, attacker, mage, healer }

class CharacterStats {
  int level;
  double xp;
  double xpToNext;
  double confidence;
  double strength;
  double defense;
  double maxHp;
  double speed;
  double intelligence;

  final CharacterClass charClass;
  final double levelMultiplier;

  CharacterStats({
    this.level = 1,
    this.xp = 0,
    this.xpToNext = 100,
    this.confidence = 10,
    this.strength = 10,
    this.defense = 10,
    this.maxHp = 50,
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
      // fallback
      return CharacterStats(charClass: defaultClass);
    }
  }

  void gainXP(double amount, {required String id}) {
    xp += amount * levelMultiplier;
    while (xp >= xpToNext) {
      xp -= xpToNext;
      levelUp();
    }
    save(id); // Save after XP gain
  }

  void levelUp() {
    level++;
    xpToNext *= 1.2;

    final growthRates = _getGrowthRates();
    confidence += growthRates['confidence']!;
    strength += growthRates['strength']!;
    defense += growthRates['defense']!;
    maxHp += growthRates['hp']!;
    speed += growthRates['speed']!;
    intelligence += growthRates['intelligence']!;
  }

  Map<String, double> _getGrowthRates() {
    switch (charClass) {
      case CharacterClass.attacker:
        return {
          'confidence': 2,
          'strength': 4,
          'defense': 2,
          'hp': 5,
          'speed': 2,
          'intelligence': 1,
        };
      case CharacterClass.mage:
        return {
          'confidence': 2,
          'strength': 1,
          'defense': 1,
          'hp': 3,
          'speed': 2,
          'intelligence': 5,
        };
      case CharacterClass.healer:
        return {
          'confidence': 3,
          'strength': 1,
          'defense': 2,
          'hp': 4,
          'speed': 2,
          'intelligence': 3,
        };
      case CharacterClass.balanced:
      default:
        return {
          'confidence': 2,
          'strength': 2,
          'defense': 2,
          'hp': 4,
          'speed': 2,
          'intelligence': 2,
        };
    }
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'xp': xp,
    'xpToNext': xpToNext,
    'confidence': confidence,
    'strength': strength,
    'defense': defense,
    'maxHp': maxHp,
    'speed': speed,
    'intelligence': intelligence,
    'charClass': charClass.toString().split('.').last,
    'levelMultiplier': levelMultiplier,
  };

  static CharacterStats fromJson(Map<String, dynamic> json) {
    return CharacterStats(
      level: json['level'],
      xp: json['xp'],
      xpToNext: json['xpToNext'],
      confidence: json['confidence'],
      strength: json['strength'],
      defense: json['defense'],
      maxHp: json['maxHp'],
      speed: json['speed'],
      intelligence: json['intelligence'],
      charClass: CharacterClass.values.firstWhere(
        (e) => e.toString().split('.').last == json['charClass'],
      ),
      levelMultiplier: json['levelMultiplier'],
    );
  }
}
