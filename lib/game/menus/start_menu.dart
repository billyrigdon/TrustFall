import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';

class StartMenu extends StatefulWidget {
  final TrustFall game;

  const StartMenu({super.key, required this.game});

  @override
  State<StartMenu> createState() => StartMenuState();
}

class StartMenuState extends State<StartMenu> {
  int selectedIndex = 0;
  final List<String> options = ['New Game', 'Load Game', 'Settings', 'Exit'];
  final SettingsService settings = SettingsService();

  bool isReady = false;

  @override
  void initState() {
    super.initState();

    SettingsService().load().then((_) {
      setState(() {
        isReady = true;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
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
        widget.game.playerIsInMenu = false;
        widget.game.overlays.add('SettingsMenu');
        widget.game.keyboardListenerKey.currentState?.regainFocus();
        widget.game.ensureTouchControls();
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
      ],
    );
  }
}
