import 'package:flame/components.dart';
import 'package:game/features/characters/battle_character.dart';
import 'package:game/main.dart';
import 'package:game/services/attacks.dart';
// import 'package:game/models/battle_character.dart';
// import 'package:game/models/character_stats.dart';
import 'package:game/services/character_stats.dart';

class TestPartyMember extends SpriteAnimationComponent
    with HasGameRef<TrustFall>
    implements BattleCharacter {
  @override
  final String name;

  @override
  CharacterStats stats;

  @override
  int currentHP;

  TestPartyMember({required this.name, required this.stats})
    : currentHP = stats.hp.toInt(),
      super(size: Vector2(48, 80), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList([
      await gameRef.loadSprite('sprite.png'),
    ], stepTime: 1.0);

    attacks = [
      Attack(name: 'Slash', type: AttackType.normal, power: 1.0),
      Attack(name: 'Inspire', type: AttackType.fire, power: 1.2),
    ];
  }

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
  late List<Attack> attacks;

  @override
  void gainXpFromEnemy({required double baseXp, required int enemyLevel}) {
    // TODO: implement gainXpFromEnemy
  }

  @override
  set name(String _name) {
    // TODO: implement name
  }
}
