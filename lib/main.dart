import 'dart:io' show Platform;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:game/game/battle/battle_overlay.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/game/characters/enemies/test_enemy.dart';
import 'package:game/game/characters/main_player.dart';
import 'package:game/game/menus/pause_menu.dart';
import 'package:game/game/menus/settings_menu.dart';
import 'package:game/game/menus/start_menu.dart';
import 'package:game/game/scenes/main_player_house/main_player_house.dart';
import 'package:game/game/scenes/main_player_house/main_player_house_room.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/touch_overlay.dart';
import 'package:game/widgets/trust_fall_text_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().load();
  final startMenuKey = GlobalKey<StartMenuState>();

  runApp(
    MaterialApp(
      title: 'TrustFall',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget(
          game: TrustFall(startMenuKey),
          overlayBuilderMap: {
            if (Platform.isAndroid || Platform.isIOS)
              'TouchControls':
                  (context, game) => TouchControls(
                    onInput:
                        (label, isPressed) =>
                            (game as TrustFall).handleInput(label, isPressed),
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
            'StartMenu':
                (context, game) =>
                    StartMenu(key: startMenuKey, game: game as TrustFall),

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
  StartMenu? startMenu; // If you need access to StartMenu methods
  bool playerIsInMenu = true;
  bool inBattle = false;
  final GlobalKey<StartMenuState> startMenuKey;
  TrustFall(this.startMenuKey);

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
    // prefs.clear();
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

  void handleInput(String label, bool isPressed) {
    if (playerIsInMenu) {
      if (isPressed) {
        startMenuKey.currentState?.handleInput(label);
      }
    } else {
      player.handleTouchInput(label, isPressed);
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
