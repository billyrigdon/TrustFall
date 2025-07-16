import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';
import 'package:gamepads/gamepads.dart';

class StartMenu extends StatefulWidget {
  final TrustFall game;
  // final startMenuKey = GlobalKey<_StartMenuState>();

  StartMenu({super.key, required this.game});

  @override
  State<StartMenu> createState() => StartMenuState();
}

class StartMenuState extends State<StartMenu> {
  int selectedIndex = 0;
  final List<String> options = ['New Game', 'Load Game', 'Settings', 'Exit'];
  final SettingsService settings = SettingsService();

  StreamSubscription<GamepadEvent>? _gamepadSub;

  bool isReady = false;

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_onKey);
    _gamepadSub = Gamepads.events.listen(_onGamepad);

    SettingsService().load().then((_) {
      setState(() {
        isReady = true;
      });
    });
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_onKey);
    _gamepadSub?.cancel();
    super.dispose();
  }

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final keyLabel =
        event.logicalKey.keyLabel.isEmpty
            ? event.logicalKey.debugName ?? ''
            : event.logicalKey.keyLabel;

    handleInput(keyLabel);
  }

  void _onGamepad(GamepadEvent event) {
    final typeString = event.type.toString();

    final isAxis = typeString.contains('axis') || typeString.contains('analog');

    if (isAxis && event.value.abs() > 0.9) {
      final direction = event.value > 0 ? '+' : '-';
      final input = '${event.gamepadId}:${event.key}:$direction';

      final up = settings.getBinding('MoveUp');
      final down = settings.getBinding('MoveDown');
      final left = settings.getBinding('MoveLeft');
      final right = settings.getBinding('MoveRight');

      print(
        '[Axis] input=$input | up=$up, down=$down, left=$left, right=$right',
      );

      if (input == up)
        handleInput(up);
      else if (input == down)
        handleInput(down);
      else if (input == left)
        handleInput(left);
      else if (input == right)
        handleInput(right);
    }

    if (event.type == KeyType.button && event.value == 1.0) {
      final input = '${event.gamepadId}:${event.key}';
      final action = settings.getBinding('Action');
      print('[Button] input=$input | action=$action');
      if (input == action) handleInput(action);
    }
  }

  void handleInput(String inputLabel) {
    if (!isReady) return;

    final up = settings.getBinding('MoveUp');
    final down = settings.getBinding('MoveDown');
    final action = settings.getBinding('Action');

    final isUp =
        inputLabel == up ||
        inputLabel == 'Arrow Up' ||
        inputLabel == LogicalKeyboardKey.arrowUp.keyLabel;

    final isDown =
        inputLabel == down ||
        inputLabel == 'Arrow Down' ||
        inputLabel == LogicalKeyboardKey.arrowDown.keyLabel;

    final isAction =
        inputLabel == action ||
        inputLabel == 'Enter' ||
        inputLabel == LogicalKeyboardKey.enter.keyLabel ||
        inputLabel == 'Space' ||
        inputLabel == LogicalKeyboardKey.space.keyLabel;

    if (isDown) {
      setState(() => selectedIndex = (selectedIndex + 1) % options.length);
    } else if (isUp) {
      setState(
        () =>
            selectedIndex =
                (selectedIndex - 1 + options.length) % options.length,
      );
    } else if (isAction) {
      _onSelect();
    }
  }

  void _onSelect() {
    final selection = options[selectedIndex];
    switch (selection) {
      case 'New Game':
        widget.game.overlays.remove('StartMenu');
        widget.game.playerIsInMenu = false;
        widget.game.resumeEngine();
        break;
      case 'Load Game':
        break;
      case 'Settings':
        widget.game.overlays.remove('StartMenu');
        widget.game.overlays.remove('TouchControls');
        widget.game.playerIsInSettingsMenu = true;
        widget.game.overlays.add('SettingsMenu');
        widget.game.ensureTouchControls();
        widget.game.playerIsInMenu = false;

        // if (Platform.isAndroid) widget.game.overlays.add('TouchControls');
        // widget.game.resumeEngine();
        break;
      case 'Exit':
        Future.delayed(const Duration(milliseconds: 200), () {
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          WidgetsBinding.instance.handlePopRoute();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const Material(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Material(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(options.length, (i) {
                final selected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${selected ? '▶' : '  '} ${options[i]}',
                    style: TextStyle(
                      fontSize: 24,
                      color: selected ? Colors.amber : Colors.white,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        // 👇 Touch controls here
        // if (Platform.isAndroid || Platform.isIOS)
        //   Positioned.fill(
        //     child: TouchControls(
        //       onInput: (label, isPressed) {
        //         if (isPressed) {
        //           _handleInput(label);
        //         }
        //       },
        //     ),
        //   ),
      ],
    );
  }
}
