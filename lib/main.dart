import 'dart:io' show Platform;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:game/features/battle/battle_overlay.dart';
import 'package:game/features/characters/battle_character.dart';
import 'package:game/features/characters/enemies/test_enemy.dart';
import 'package:game/features/characters/main_player.dart';
import 'package:game/features/menus/pause_menu.dart';
import 'package:game/features/menus/settings_menu.dart';
import 'package:game/features/menus/start_menu.dart';
import 'package:game/maps/main_player_house/main_player_house.dart';
import 'package:game/maps/main_player_house/model/main_player_house_room.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/touch_overlay.dart';
import 'package:game/widgets/trust_fall_text_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().load();
  runApp(
    MaterialApp(
      title: 'TrustFall',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget(
          game: TrustFall(),
          overlayBuilderMap: {
            if (Platform.isAndroid)
              'TouchControls':
                  (context, game) => TouchControls(
                    onInput: (label, isPressed) {
                      final player = (game as TrustFall).player;
                      player.handleTouchInput(label, isPressed);
                    },
                  ),
            'TextBox': (context, game) => const TrustFallTextBox(),
            'PauseMenu':
                (context, game) =>
                    PauseMenu(player: (game as TrustFall).player),
            'BattleOverlay': (context, game) {
              final trustFall = game as TrustFall;
              return BattleOverlay(
                game: trustFall,
                party: trustFall.currentParty,
                enemy: trustFall.currentEnemy,
              );
            },
            'StartMenu': (context, game) => StartMenu(game: game as TrustFall),
            'SettingsMenu':
                (context, game) => SettingsMenu(game: game as TrustFall),
          },
          initialActiveOverlays: const ['StartMenu'],
        ),
      ),
    ),
  );
}

class TrustFall extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late MainPlayer player;
  List<BattleCharacter> currentParty = [];
  late Enemy currentEnemy;
  bool isPaused = false;

  bool inBattle = false;

  void startBattle(List<BattleCharacter> party, Enemy enemy) {
    currentParty = party;

    currentEnemy = enemy;

    inBattle = true;
    overlays.add('BattleOverlay');
  }

  void endBattle() {
    inBattle = false;
    overlays.remove('BattleOverlay');
  }

  @override
  Future<void> onLoad() async {
    player = MainPlayer();
    final prefs = await SharedPreferences.getInstance();
    final loader = prefs.getString('currentLoader') ?? 'mainPlayerHouse';

    switch (loader) {
      case 'mainPlayerHouse':
      default:
        add(MainPlayerHouse(MainPlayerHouseRoom.living_room));
    }
  }

  @override
  void update(double dt) {
    if (!isPaused) {
      super.update(dt);
    }
  }

  void togglePause() {
    isPaused = !isPaused;
    if (isPaused) {
      overlays.add('PauseMenu');
    } else {
      overlays.remove('PauseMenu');
    }
  }

  void showTextBox() {
    overlays.add('TextBox');
    Future.delayed(const Duration(seconds: 2), () {
      overlays.remove('TextBox');
    });
  }
}

// class Wall extends PositionComponent with CollisionCallbacks {
//   Wall(Vector2 position, Vector2 size) {
//     this.position = position;
//     this.size = size;
//     add(
//       RectangleHitbox()..collisionType = CollisionType.passive, // important!
//     );
//   }
// }
class Wall extends PositionComponent with CollisionCallbacks {
  Wall(Vector2 pos, Vector2 size)
    : super(position: pos, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }
}
