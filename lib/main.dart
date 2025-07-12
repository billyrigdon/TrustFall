import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:game/features/battle/battle_overlay.dart';
import 'package:game/features/characters/main_player.dart';
import 'package:game/features/menus/pause_menu.dart';
import 'package:game/features/menus/settings_menu.dart';
import 'package:game/features/menus/start_menu.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/trust_fall_text_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // runApp(
  //   GameWidget(
  //     game: TrustFall(),
  //     overlayBuilderMap: {
  //       'TextBox': (context, game) => const TrustFallTextBox(),
  //       'PauseMenu': (context, game) => const PauseMenu(),
  //       'BattleOverlay':
  //           (context, game) => BattleOverlay(game: game as TrustFall),
  //       'StartMenu': (context, game) => StartMenu(game: game as TrustFall),
  //       'SettingsMenu':
  //           (context, game) => SettingsMenu(game: game as TrustFall),
  //     },
  //     initialActiveOverlays: const ['StartMenu'],
  //   ),
  // );
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().load(); // <- load settings early
  // var prefs = await SharedPreferences.getInstance();
  // await prefs.clear();
  runApp(
    MaterialApp(
      title: 'TrustFall',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget(
          game: TrustFall(),
          overlayBuilderMap: {
            'TextBox': (context, game) => const TrustFallTextBox(),
            'PauseMenu': (context, game) => const PauseMenu(),
            'BattleOverlay':
                (context, game) => BattleOverlay(game: game as TrustFall),
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
  late final MainPlayer player;
  bool isPaused = false;

  bool inBattle = false;

  void startBattle() {
    inBattle = true;
    overlays.add('BattleOverlay');
  }

  void endBattle() {
    inBattle = false;
    overlays.remove('BattleOverlay');
  }

  @override
  Future<void> onLoad() async {
    final map = await TiledComponent.load('test_map.tmx', Vector2.all(32));
    player = MainPlayer()..position = Vector2(100, 100);

    world = World()..addAll([map, player]);
    camera.follow(player);

    final mapWidth = map.tileMap.map.width * map.tileMap.map.tileWidth;
    final mapHeight = map.tileMap.map.height * map.tileMap.map.tileHeight;
    camera.setBounds(
      Rectangle.fromLTWH(0, 0, mapWidth.toDouble(), mapHeight.toDouble()),
    );
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
