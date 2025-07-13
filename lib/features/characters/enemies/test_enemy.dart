// import 'package:game/features/characters/battle_character.dart';
// import 'package:game/services/character_stats.dart';

// class Enemy extends BattleCharacter {
//   final int level;

//   Enemy({
//     required String name,
//     required this.level,
//     required CharacterStats stats,
//   }) : super(name: name, stats: stats);
// }
import 'package:flame/components.dart';
import 'package:game/features/characters/battle_character.dart';
import 'package:game/services/attacks.dart';
import 'package:game/services/character_stats.dart';
// import 'package:game/models/attack.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Image, Widget;
import 'package:game/features/characters/battle_character.dart';
// import 'package:game/models/attack.dart';
import 'package:game/services/character_stats.dart';

class Enemy extends SpriteComponent with HasGameRef implements BattleCharacter {
  @override
  final String name;

  @override
  final CharacterStats stats;

  @override
  int currentHP = 10;

  @override
  final List<Attack> attacks;

  final int level;

  Enemy({
    required this.name,
    required this.level,
    required this.stats,
    required this.attacks,
  }) : currentHP = stats.hp.toInt(),
       super(size: Vector2(64, 64), anchor: Anchor.center);

  /// Load sprite into Flame for in-world rendering (not shown in overlay)
  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('sprite.png');
  }

  /// Used by the battle overlay (a Flutter widget)
  Widget get imageWidget =>
      Image.asset('assets/images/sprite.png', width: 64, height: 64);

  @override
  bool get isAlive => currentHP > 0;

  @override
  void takeDamage(int damage) {
    currentHP = (currentHP - damage).clamp(0, stats.hp.toInt());
  }

  @override
  void heal(int amount) {
    currentHP = (currentHP + amount).clamp(0, stats.hp.toInt());
  }

  @override
  void gainXpFromEnemy({required double baseXp, required int enemyLevel}) {
    // Enemies don't level
  }

  @override
  set attacks(List<Attack> _attacks) {
    // TODO: implement attacks
  }

  @override
  set name(String _name) {
    // TODO: implement name
  }

  @override
  set stats(CharacterStats _stats) {
    // TODO: implement stats
  }
}
