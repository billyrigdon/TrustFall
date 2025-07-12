import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';
import 'package:gamepads/gamepads.dart';

// class MainPlayer extends SpriteAnimationComponent
//     with KeyboardHandler, HasGameRef<TrustFall> {
//   final double speed = 100.0;
//   Vector2 moveDirection = Vector2.zero();

//   late SpriteAnimation idleAnimation;
//   late SpriteAnimation walkAnimation;
//   late SpriteAnimation diagAnimation;

//   final settings = SettingsService();
//   StreamSubscription<GamepadEvent>? _gamepadSub;
//   final Set<String> _activeInputs = {};

//   MainPlayer() : super(size: Vector2(48, 80), anchor: Anchor.center);

//   @override
//   Future<void> onLoad() async {
//     idleAnimation = SpriteAnimation.spriteList([
//       await gameRef.loadSprite('sprite.png'),
//     ], stepTime: 1.0);

//     walkAnimation = SpriteAnimation.spriteList([
//       await gameRef.loadSprite('sprite_right_1.png'),
//       await gameRef.loadSprite('sprite_right_2.png'),
//     ], stepTime: 0.2);

//     diagAnimation = SpriteAnimation.spriteList([
//       await gameRef.loadSprite('sprite_bottom_right_1.png'),
//     ], stepTime: 0.2);

//     animation = idleAnimation;

//     // Start listening to gamepad events
//     _gamepadSub = Gamepads.events.listen((event) {
//       final label = 'Gamepad:${event.key}';
//       if (event.value > 0) {
//         _activeInputs.add(label);
//       } else {
//         _activeInputs.remove(label);
//       }
//     });
//   }

//   @override
//   void onRemove() {
//     _gamepadSub?.cancel();
//     super.onRemove();
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);
//     moveDirection = Vector2.zero();

//     final up = settings.getBinding('MoveUp');
//     final down = settings.getBinding('MoveDown');
//     final left = settings.getBinding('MoveLeft');
//     final right = settings.getBinding('MoveRight');

//     // Gamepad movement
//     if (_activeInputs.contains(up)) moveDirection.y -= 1;
//     if (_activeInputs.contains(down)) moveDirection.y += 1;
//     if (_activeInputs.contains(left)) moveDirection.x -= 1;
//     if (_activeInputs.contains(right)) moveDirection.x += 1;

//     // Movement from keyboard (prioritized second to override if both are used)
//     if (moveDirection == Vector2.zero()) {
//       if (_activeInputs.contains(up)) moveDirection.y -= 1;
//       if (_activeInputs.contains(down)) moveDirection.y += 1;
//       if (_activeInputs.contains(left)) moveDirection.x -= 1;
//       if (_activeInputs.contains(right)) moveDirection.x += 1;
//     }

//     if (moveDirection.length > 0) {
//       moveDirection.normalize();
//       position += moveDirection * speed * dt;
//       animation =
//           (moveDirection.x.abs() > 0 && moveDirection.y.abs() > 0)
//               ? diagAnimation
//               : walkAnimation;
//     } else {
//       animation = idleAnimation;
//     }
//   }

//   @override
//   bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
//     final keyLabel =
//         event.logicalKey.keyLabel.isEmpty
//             ? event.logicalKey.debugName ?? ''
//             : event.logicalKey.keyLabel;

//     if (event is KeyDownEvent) {
//       _activeInputs.add(keyLabel);

//       final action = settings.getBinding('Action');
//       if (keyLabel == action) {
//         gameRef.showTextBox();
//         return true;
//       }

//       if (keyLabel == 'Key P') {
//         gameRef.togglePause();
//         return true;
//       }

//       if (keyLabel == 'Key B' && !gameRef.inBattle) {
//         gameRef.startBattle();
//         return true;
//       }
//     } else if (event is KeyUpEvent) {
//       _activeInputs.remove(keyLabel);
//     }

//     return true;
//   }
// }

class MainPlayer extends SpriteAnimationComponent
    with KeyboardHandler, HasGameRef<TrustFall> {
  final double speed = 100.0;
  Vector2 moveDirection = Vector2.zero();

  late SpriteAnimation idleAnimation;
  late SpriteAnimation walkAnimation;
  late SpriteAnimation diagAnimation;

  final settings = SettingsService();
  StreamSubscription<GamepadEvent>? _gamepadSub;
  final Set<String> _activeInputs = {};

  MainPlayer() : super(size: Vector2(48, 80), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
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

    await settings.load();

    _gamepadSub = Gamepads.events.listen((event) {
      final typeStr = event.type.toString();
      final isAxis = typeStr.contains('axis') || typeStr.contains('analog');
      final isButton = event.type == KeyType.button;

      String? input;

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
          // Analog returned to neutral — remove both directions
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
          if (input == battle && !gameRef.inBattle) gameRef.startBattle();
        } else if (event.value == 0.0) {
          _activeInputs.remove(input);
        }
      }
    });
  }

  @override
  void onRemove() {
    _gamepadSub?.cancel();
    super.onRemove();
  }

  @override
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

      final isTalk = keyLabel == talk || keyLabel == 'Space';
      final isPause = keyLabel == pause || keyLabel == 'Key P';
      final isBattle = keyLabel == battle || keyLabel == 'Key B';

      if (isTalk) {
        gameRef.showTextBox();
        return true;
      }

      if (isPause) {
        gameRef.togglePause();
        return true;
      }

      if (isBattle && !gameRef.inBattle) {
        gameRef.startBattle();
        return true;
      }
    } else if (event is KeyUpEvent) {
      _activeInputs.remove(keyLabel);
    }

    return true;
  }
}
