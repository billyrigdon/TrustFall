import 'dart:io' show Platform;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:game/game/battle/battle_overlay.dart';
import 'package:game/models/attacks.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/game/characters/enemies/test_enemy.dart';
import 'package:game/game/characters/main_player.dart';
import 'package:game/game/menus/pause_menu.dart';
import 'package:game/game/menus/settings_menu.dart';
import 'package:game/game/menus/start_menu.dart';
import 'package:game/game/scenes/main_player_house/main_player_house.dart';
import 'package:game/game/scenes/main_player_house/main_player_house_room.dart';
import 'package:game/models/character_stats.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/touch_overlay.dart';
import 'package:game/widgets/trust_fall_text_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().load();
  final startMenuKey = GlobalKey<StartMenuState>();
  final settingsMenuKey = GlobalKey<SettingsMenuState>();
  final pauseMenuKey = GlobalKey<PauseMenuState>();
  final battleMenuKey = GlobalKey<BattleOverlayState>();

  runApp(
    MaterialApp(
      title: 'TrustFall',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget(
          game: TrustFall(
            startMenuKey,
            settingsMenuKey,
            pauseMenuKey,
            battleMenuKey,
          ),
          overlayBuilderMap: {
            'TextBox': (context, game) => const TrustFallTextBox(),
            'PauseMenu':
                (context, game) => PauseMenu(
                  key: pauseMenuKey,
                  player: (game as TrustFall).player,
                ),
            'BattleOverlay': (context, game) {
              final trustFall = game as TrustFall;
              return BattleOverlay(
                key: battleMenuKey,
                game: trustFall,
                party: trustFall.currentParty,
                enemy: trustFall.currentEnemy,
              );
            },
            'StartMenu':
                (context, game) =>
                    StartMenu(key: startMenuKey, game: game as TrustFall),

            'SettingsMenu':
                (context, game) =>
                    SettingsMenu(key: settingsMenuKey, game: game as TrustFall),
            if (Platform.isAndroid || Platform.isIOS)
              'TouchControls':
                  (context, game) => TouchControls(
                    onInput:
                        (label, isPressed) => (game as TrustFall)
                            .handleTouchInput(label, isPressed),
                  ),
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
  bool playerIsInSettingsMenu = false;
  bool inBattle = false;
  final GlobalKey<StartMenuState> startMenuKey;
  final GlobalKey<SettingsMenuState> settingsMenuKey;
  final GlobalKey<PauseMenuState> pauseMenuKey;
  final GlobalKey<BattleOverlayState> battleMenuKey;
  TrustFall(
    this.startMenuKey,
    this.settingsMenuKey,
    this.pauseMenuKey,
    this.battleMenuKey,
  );

  void startBattle(List<BattleCharacter> party, Enemy enemy) {
    currentParty = party;

    currentEnemy = enemy;
    overlays.remove('TouchControls');
    inBattle = true;
    overlays.add('BattleOverlay');
    ensureTouchControls();
  }

  void ensureTouchControls() {
    if ((Platform.isAndroid || Platform.isIOS) &&
        !overlays.isActive('TouchControls')) {
      overlays.add('TouchControls');
    }
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

  void handleTouchInput(String label, bool isPressed) {
    if (playerIsInMenu && !playerIsInSettingsMenu) {
      if (isPressed) {
        startMenuKey.currentState?.handleInput(label);
      }
    } else if (inBattle) {
      if (isPressed) {
        print(label);
        print('sending to handler battle');
        battleMenuKey.currentState?.handleInput(label);
      }
    } else if (isPaused) {
      if (isPressed) {
        if (label == 'Key P') togglePause();
        pauseMenuKey.currentState?.handleInput(label);
      }
    } else if (playerIsInSettingsMenu) {
      if (isPressed) {
        settingsMenuKey.currentState?.handleInput(label);
      }
    } else {
      if (isPressed) {
        if (label == 'Enter') showTextBox();
        if (label == 'Key P') togglePause();
        if (label == 'Key B' && !inBattle) {
          startBattle(
            [player, ...currentParty],
            Enemy(
              name: 'Cat',
              level: 2,
              stats: CharacterStats(
                charClass: CharacterClass.balanced,
                maxHp: 60,
                strength: 10,
              ),
              attacks: [
                Attack(name: 'Punch', type: AttackType.physical, power: 1.0),
              ],
            ),
          );
        }
      }

      player.handleTouchInput(label, isPressed);
    }
  }

  void togglePause() {
    isPaused = !isPaused;
    overlays.remove('TouchControls');
    if (isPaused) {
      overlays.add('PauseMenu');
    } else {
      overlays.remove('PauseMenu');
    }
    ensureTouchControls();
  }

  void showTextBox() {
    overlays.add('TextBox');
    Future.delayed(const Duration(seconds: 2), () {
      overlays.remove('TextBox');
    });
  }
}
