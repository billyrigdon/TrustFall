import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:game/features/characters/battle_character.dart';
import 'package:game/features/characters/enemies/test_enemy.dart';
import 'package:game/features/characters/party/test_friend.dart';
import 'package:game/main.dart';
import 'package:game/services/attacks.dart';
import 'package:game/services/character_stats.dart';
import 'package:game/services/settings_service.dart';
import 'package:gamepads/gamepads.dart';

class MainPlayer extends SpriteAnimationComponent
    with KeyboardHandler, CollisionCallbacks, HasGameRef<TrustFall>
    implements BattleCharacter {
  final double speed = 100.0;
  Vector2 moveDirection = Vector2.zero();
  Vector2 _lastSafePosition = Vector2.zero();

  @override
  late List<Attack> attacks;

  @override
  late CharacterStats stats;

  @override
  int currentHP = 0;

  @override
  String name = "Main Player";

  late SpriteAnimation idleAnimation;
  late SpriteAnimation walkAnimation;
  late SpriteAnimation diagAnimation;

  final settings = SettingsService();
  StreamSubscription<GamepadEvent>? _gamepadSub;
  final Set<String> _activeInputs = {};

  MainPlayer() : super(size: Vector2(48, 80), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    debugMode = true;

    await settings.load();

    add(
      RectangleHitbox.relative(
        Vector2(1, 0.5), // width: 60%, height: 50%
        parentSize: size,
        position: Vector2(1, 40), // place it at the halfway mark
        anchor:
            Anchor
                .topLeft, // anchor hitbox to top-left of its relative position
      )..collisionType = CollisionType.active,
    );

    // Load sprites
    idleAnimation = SpriteAnimation.spriteList([
      await gameRef.loadSprite('sprite.png'),
    ], stepTime: 1.0);

    walkAnimation = SpriteAnimation.spriteList([
      await gameRef.loadSprite('sprite_right_1.png'),
      await gameRef.loadSprite('sprite_right_2.png'),
    ], stepTime: 0.2);

    diagAnimation = SpriteAnimation.spriteList([
      await gameRef.loadSprite('sprite_bottom_right_1.png'),
    ], stepTime: 0.2);

    animation = idleAnimation;

    _gamepadSub = Gamepads.events.listen(_handleGamepad);

    stats = CharacterStats(charClass: CharacterClass.balanced);

    attacks = [
      Attack(name: 'Slash', type: AttackType.normal, power: 1.0),
      Attack(name: 'Inspire', type: AttackType.fire, power: 1.2),
    ];
  }

  void _handleGamepad(GamepadEvent event) {
    final typeStr = event.type.toString();
    final isAxis = typeStr.contains('axis') || typeStr.contains('analog');
    final isButton = event.type == KeyType.button;

    if (isAxis) {
      final positive = '${event.gamepadId}:${event.key}:+';
      final negative = '${event.gamepadId}:${event.key}:-';

      if (event.value >= 0.9) {
        _activeInputs.add(positive);
        _activeInputs.remove(negative);
      } else if (event.value <= -0.9) {
        _activeInputs.add(negative);
        _activeInputs.remove(positive);
      } else {
        _activeInputs.remove(positive);
        _activeInputs.remove(negative);
      }
    }

    if (isButton) {
      final input = '${event.gamepadId}:${event.key}';

      final action = settings.getBinding('Action');
      final pause = settings.getBinding('Pause');
      final battle = settings.getBinding('Battle');
      final talk = settings.getBinding('Talk');

      if (event.value == 1.0) {
        if (input == action) _activeInputs.add(input);
        if (input == talk) gameRef.showTextBox();
        if (input == pause) gameRef.togglePause();
        if (input == battle && !gameRef.inBattle)
          gameRef.startBattle(
            [
              this,
              TestPartyMember(
                name: 'Buddy',
                stats: CharacterStats(charClass: CharacterClass.attacker),
              ),
            ],
            Enemy(
              name: 'Slime Cat',
              level: 2,
              stats: CharacterStats(
                charClass: CharacterClass.balanced,
                hp: 60,
                strength: 10,
              ),
              attacks: [
                Attack(name: 'Scratch', type: AttackType.normal, power: 1.0),
              ],
            ),
          );
      } else if (event.value == 0.0) {
        _activeInputs.remove(input);
      }
    }
  }

  bool _checkInput(String binding, List<String> fallbacks) {
    return _activeInputs.contains(binding) ||
        fallbacks.any(_activeInputs.contains);
  }

  @override
  void update(double dt) {
    super.update(dt);
    moveDirection = Vector2.zero();

    final up = settings.getBinding('MoveUp');
    final down = settings.getBinding('MoveDown');
    final left = settings.getBinding('MoveLeft');
    final right = settings.getBinding('MoveRight');

    if (_checkInput(up, ['Arrow Up', 'W', 'w'])) moveDirection.y -= 1;
    if (_checkInput(down, ['Arrow Down', 'S', 's'])) moveDirection.y += 1;
    if (_checkInput(left, ['Arrow Left', 'A', 'a'])) moveDirection.x -= 1;
    if (_checkInput(right, ['Arrow Right', 'D', 'd'])) moveDirection.x += 1;

    if (moveDirection.length > 0) {
      _lastSafePosition = position.clone(); // save last valid position
      moveDirection.normalize();
      position += moveDirection * speed * dt;

      animation =
          (moveDirection.x.abs() > 0 && moveDirection.y.abs() > 0)
              ? diagAnimation
              : walkAnimation;
    } else {
      animation = idleAnimation;
    }
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is Wall) {
      position = _lastSafePosition; // revert to last known good position
    }
  }

  @override
  void onRemove() {
    _gamepadSub?.cancel();
    super.onRemove();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final keyLabel =
        event.logicalKey.keyLabel.isEmpty
            ? event.logicalKey.debugName ?? ''
            : event.logicalKey.keyLabel;

    if (event is KeyDownEvent) {
      _activeInputs.add(keyLabel);

      final talk = settings.getBinding('Talk');
      final pause = settings.getBinding('Pause');
      final battle = settings.getBinding('Battle');

      if (keyLabel == talk || keyLabel == 'Space') gameRef.showTextBox();
      if (keyLabel == pause || keyLabel == 'Key P') gameRef.togglePause();
      if ((keyLabel == battle || keyLabel == 'Key B') && !gameRef.inBattle) {
        gameRef.startBattle(
          [
            this,
            TestPartyMember(
              name: 'Buddy',
              stats: CharacterStats(charClass: CharacterClass.attacker),
            ),
          ],
          Enemy(
            name: 'Slime Cat',
            level: 2,
            stats: CharacterStats(
              charClass: CharacterClass.balanced,
              hp: 60,
              strength: 10,
            ),
            attacks: [
              Attack(name: 'Scratch', type: AttackType.normal, power: 1.0),
            ],
          ),
        );
      }
    } else if (event is KeyUpEvent) {
      _activeInputs.remove(keyLabel);
    }

    return true;
  }

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
    final levelDiff = enemyLevel - stats.level;
    final modifier = 1.0 + (levelDiff * 0.1);
    stats.gainXP(baseXp * modifier.clamp(0.5, 2.0));
  }

  @override
  bool get isAlive => currentHP > 0;
}
