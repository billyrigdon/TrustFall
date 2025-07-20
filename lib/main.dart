import 'dart:io' show Platform;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:game/game/battle/battle_overlay.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/enemy.dart';
import 'package:game/game/main_player/main_player.dart';
import 'package:game/game/menus/pause_menu.dart';
import 'package:game/game/menus/settings_menu.dart';
import 'package:game/game/menus/start_menu.dart';
import 'package:game/game/scenes/main_player_house/main_player_house.dart';
import 'package:game/game/scenes/main_player_house/rooms/main_player_house_room.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/keyboard_gamepad_handler.dart';
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
  final keyboardListenerKey = GlobalKey<KeyboardGamepadListenerState>();
  final GlobalKey<TrustFallTextBoxState> textBoxKey = GlobalKey();

  final trustFallGame = TrustFall(
    startMenuKey,
    settingsMenuKey,
    pauseMenuKey,
    battleMenuKey,
    keyboardListenerKey,
    textBoxKey,
  );

  final inputHandler = trustFallGame.handleTouchInput;

  runApp(
    MaterialApp(
      title: 'TrustFall',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            GameWidget(
              game: trustFallGame,
              overlayBuilderMap: {
                'TextBox':
                    (context, _) =>
                        TrustFallTextBox(key: textBoxKey, game: trustFallGame),
                'PauseMenu':
                    (context, _) => PauseMenu(
                      key: pauseMenuKey,
                      player: trustFallGame.player,
                    ),
                'BattleOverlay': (context, _) {
                  return BattleOverlay(
                    key: battleMenuKey,
                    game: trustFallGame,
                    party: trustFallGame.currentParty,
                    enemy: trustFallGame.currentEnemy,
                  );
                },
                'StartMenu':
                    (context, _) =>
                        StartMenu(key: startMenuKey, game: trustFallGame),

                'SettingsMenu':
                    (context, _) =>
                        SettingsMenu(key: settingsMenuKey, game: trustFallGame),
                if (Platform.isAndroid || Platform.isIOS)
                  'TouchControls':
                      (context, _) => TouchControls(
                        onInput:
                            (label, isPressed) => trustFallGame
                                .handleTouchInput(label, isPressed),
                      ),
              },
              initialActiveOverlays: const ['StartMenu'],
            ),
            KeyboardGamepadListener(
              key: keyboardListenerKey,
              onInput: inputHandler,
              inputMode:
                  trustFallGame.inMenu
                      ? GamepadInputMode.menu
                      : GamepadInputMode.movement,
            ),
          ],
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
  final settings = SettingsService();
  final GlobalKey<StartMenuState> startMenuKey;
  final GlobalKey<SettingsMenuState> settingsMenuKey;
  final GlobalKey<PauseMenuState> pauseMenuKey;
  final GlobalKey<BattleOverlayState> battleMenuKey;
  final GlobalKey<KeyboardGamepadListenerState> keyboardListenerKey;
  final GlobalKey<TrustFallTextBoxState> textBoxKey;
  Vector2 mapPixelSize = Vector2.zero();
  bool dialogOpen = false;

  bool get inMenu =>
      overlays.isActive('StartMenu') ||
      overlays.isActive('PauseMenu') ||
      overlays.isActive('SettingsMenu') ||
      overlays.isActive('BattleOverlay');

  TrustFall(
    this.startMenuKey,
    this.settingsMenuKey,
    this.pauseMenuKey,
    this.battleMenuKey,
    this.keyboardListenerKey,
    this.textBoxKey,
  );

  void startBattle(List<BattleCharacter> party, Enemy enemy) {
    currentParty = party;

    currentEnemy = enemy;
    overlays.remove('TouchControls');
    inBattle = true;
    overlays.add('BattleOverlay');
    keyboardListenerKey.currentState?.regainFocus();

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
    keyboardListenerKey.currentState?.regainFocus();

    ensureTouchControls();
  }

  @override
  Future<void> onLoad() async {
    player = MainPlayer();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
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

  void returnToStartMenu() {
    overlays.remove('SettingsMenu');
    if (Platform.isAndroid || Platform.isIOS) overlays.remove('TouchControls');

    playerIsInSettingsMenu = false;
    playerIsInMenu = true;

    overlays.add('StartMenu');
    keyboardListenerKey.currentState?.regainFocus();

    if (Platform.isAndroid || Platform.isIOS) ensureTouchControls();
  }

  void handleTouchInput(String label, bool isPressed) {
    if (playerIsInMenu && !playerIsInSettingsMenu) {
      if (isPressed) {
        startMenuKey.currentState?.handleInput(label);
      }
    } else if (inBattle) {
      if (isPressed) {
        battleMenuKey.currentState?.handleInput(label);
      }
    } else if (isPaused) {
      final pause = settings.getBinding('Pause');
      if (isPressed) {
        if (label == pause || label == 'Key P' || label == 'P') togglePause();
        pauseMenuKey.currentState?.handleInput(label);
      }
    } else if (playerIsInSettingsMenu) {
      if (isPressed) {
        settingsMenuKey.currentState?.handleInput(label);
      }
    } else if (overlays.isActive('TextBox')) {
      if (isPressed) {
        textBoxKey.currentState?.handleInput(label);
      }
    } else {
      if (isPressed) {
        final back = settings.getBinding('Back');
        final pause = settings.getBinding('Pause');

        if (label == back || label == 'Backspace') {}

        if (label == pause || label == "P" || label == 'Key P') {
          togglePause();
        }
      }

      player.handleTouchInput(label, isPressed);
    }
  }

  void showDialogue(
    List<String> lines, {
    List<String>? choices,
    void Function(String choice)? onChoiceSelected,
    VoidCallback? onComplete,
  }) {
    overlays.add('TextBox');

    // Delay to ensure overlay is mounted
    Future.delayed(const Duration(milliseconds: 50), () {
      final textBoxState = textBoxKey.currentState;
      textBoxState?.startDialogue(
        lines,
        choices: choices,
        onChoiceSelected: onChoiceSelected,
        onComplete: onComplete,
      );
    });
  }

  void togglePause() {
    overlays.remove('TouchControls');
    isPaused = !isPaused;
    if (isPaused) {
      overlays.add('PauseMenu');
    } else {
      overlays.remove('PauseMenu');
    }
    keyboardListenerKey.currentState?.regainFocus();

    ensureTouchControls();
  }
}
