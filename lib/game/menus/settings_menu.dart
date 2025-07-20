import 'dart:io';

import 'package:flame/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/keybinding_row.dart';

enum SettingsItemType { keyBind, switchToggle, dropdown, slider, back }

late final List<_SettingsItemMeta> _itemMetas = [
  _SettingsItemMeta(SettingsItemType.keyBind),
  _SettingsItemMeta(SettingsItemType.keyBind),
  _SettingsItemMeta(SettingsItemType.keyBind),
  _SettingsItemMeta(SettingsItemType.keyBind),
  _SettingsItemMeta(SettingsItemType.keyBind),
  _SettingsItemMeta(SettingsItemType.keyBind),
  _SettingsItemMeta(SettingsItemType.keyBind),
  if (Platform.isAndroid) _SettingsItemMeta(SettingsItemType.switchToggle),
  _SettingsItemMeta(SettingsItemType.dropdown),
  _SettingsItemMeta(SettingsItemType.dropdown),
  _SettingsItemMeta(SettingsItemType.slider),
  _SettingsItemMeta(SettingsItemType.slider),
  _SettingsItemMeta(SettingsItemType.back),
];

class _SettingsItemMeta {
  final SettingsItemType type;

  _SettingsItemMeta(this.type);
}

class SettingsMenu extends StatefulWidget {
  final TrustFall game;
  const SettingsMenu({super.key, required this.game});

  @override
  State<SettingsMenu> createState() => SettingsMenuState();
}

class SettingsMenuState extends State<SettingsMenu> {
  double volume = 0.5;
  double fontSize = 16.0;
  String controllerScheme = 'WASD';
  String difficulty = 'Normal';
  String resolution = '1280x720';
  final service = SettingsService();
  int selectedIndex = 0;
  bool isReady = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> controllerOptions = ['WASD', 'Arrows', 'Custom'];
  final List<String> difficultyOptions = ['Easy', 'Normal', 'Hard'];
  final List<String> resolutionOptions = [
    '640x480',
    '800x600',
    '1280x720',
    '1920x1080',
  ];

  Map<String, String?> keyBindings = {
    'MoveUp': null,
    'MoveDown': null,
    'MoveLeft': null,
    'MoveRight': null,
    'Action': null,
    'Back': null,
    'Pause': null,
    'Battle': null,
  };

  int _totalItems = 0;

  final SettingsService settings = SettingsService();

  bool useDpad = false;

  @override
  void initState() {
    super.initState();

    settings.load().then((_) {
      setState(() {
        for (var action in keyBindings.keys) {
          keyBindings[action] = settings.getBinding(action);
        }
        useDpad = settings.getUseDpad();
        resolution = settings.resolution;
        isReady = true;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void handleInput(String inputLabel) {
    if (!isReady) return;

    // if (_keyRowKeys.any((k) => k.currentState?.listening == true)) return;

    final anyListening = _keyRowKeys.any(
      (k) => k.currentState?.listening == true,
    );
    if (anyListening) return;

    final up = service.getBinding('MoveUp');
    final down = service.getBinding('MoveDown');
    final left = service.getBinding('MoveLeft');
    final right = service.getBinding('MoveRight');
    final action = service.getBinding('Action');
    final back = service.getBinding('Back');

    final isUp = inputLabel == up || inputLabel == 'Arrow Up';
    final isDown = inputLabel == down || inputLabel == 'Arrow Down';
    final isLeft = inputLabel == left || inputLabel == 'Arrow Left';
    final isRight = inputLabel == right || inputLabel == 'Arrow Right';
    final isAction =
        inputLabel == action || inputLabel == 'Enter' || inputLabel == 'A';
    final isBack = inputLabel == back || inputLabel == 'Backspace';

    final type = _itemMetas[selectedIndex].type;

    if (type == SettingsItemType.keyBind && isAction) {
      final key = _keyRowKeys[selectedIndex];
      if (!(key.currentState?.listening ?? false)) {
        _triggerSelectedItem();
        return;
      }
      return;
    }

    if (isDown || isUp) {
      final direction = isDown ? 1 : -1;
      setState(() {
        selectedIndex = (selectedIndex + direction + _totalItems) % _totalItems;
      });
      _scrollToSelectedItem();
      return;
    }

    if (type == SettingsItemType.switchToggle && isAction) {
      setState(() {
        useDpad = !useDpad;
        service.useDpad = useDpad;
        settings.setUseDpad(useDpad);
      });
      return;
    }

    if (type == SettingsItemType.dropdown && (isLeft || isRight)) {
      setState(() {
        final dropdownIndex =
            _itemMetas
                .sublist(0, selectedIndex + 1)
                .where((m) => m.type == SettingsItemType.dropdown)
                .length -
            1;

        final options =
            dropdownIndex == 0 ? difficultyOptions : resolutionOptions;
        final current = dropdownIndex == 0 ? difficulty : resolution;
        final currentIndex = options.indexOf(current);
        final nextIndex =
            (currentIndex + (isRight ? 1 : -1) + options.length) %
            options.length;

        if (dropdownIndex == 0) {
          difficulty = options[nextIndex];
          service.difficulty = difficulty;
        } else {
          resolution = options[nextIndex];
          settings.setResolution(resolution).then((_) {
            widget.game.camera.viewport = FixedResolutionViewport(
              resolution: settings.resolutionToVector(resolution),
            );
          });
          // service.resolution = resolution;
        }
      });
      return;
    }

    if (type == SettingsItemType.slider && (isLeft || isRight)) {
      setState(() {
        final amount = isRight ? 0.05 : -0.05;
        final sliderIndex =
            _itemMetas
                .sublist(0, selectedIndex + 1)
                .where((m) => m.type == SettingsItemType.slider)
                .length -
            1;

        if (sliderIndex == 0) {
          volume = (volume + amount).clamp(0.0, 1.0);
          service.volume = volume;
        } else {
          fontSize = (fontSize + amount).clamp(12.0, 32.0);
          service.fontSize = fontSize;
        }
      });
      return;
    }

    if ((type == SettingsItemType.back && isAction) || isBack) {
      widget.game.returnToStartMenu();
      return;
    }
  }

  void _scrollToSelectedItem() {
    // Adjust item height if needed
    const itemHeight = 60.0; // approximate item height + margin
    _scrollController.animateTo(
      selectedIndex * itemHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget dropdownSetting({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontFamily: 'Ithica'),
        ),
        DropdownButton<String>(
          value: value,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white, fontFamily: 'Ithica'),
          items:
              options.map((o) {
                return DropdownMenuItem(value: o, child: Text(o));
              }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget carouselSetting({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String) onChanged,
  }) {
    final currentIndex = options.indexOf(value);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Ithica',
            fontSize: 24,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left, color: Colors.white),
              onPressed: () {
                final prevIndex =
                    (currentIndex - 1 + options.length) % options.length;
                onChanged(options[prevIndex]);
              },
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Ithica',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right, color: Colors.white),
              onPressed: () {
                final nextIndex = (currentIndex + 1) % options.length;
                onChanged(options[nextIndex]);
              },
            ),
          ],
        ),
      ],
    );
  }

  final List<GlobalKey<KeyBindingRowState>> _keyRowKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];

  Widget _buildKeyRow(
    String label,
    String action,
    GlobalKey<KeyBindingRowState> key,
  ) {
    return KeyBindingRow(
      key: key,
      label: label,
      action: action,
      currentBinding: keyBindings[action],
      onBind: (binding) async {
        await SettingsService().bindAction(action, binding);
        setState(() => keyBindings[action] = binding);
      },
    );
  }

  Widget _buildSwitchRow(String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontFamily: 'Ithica'),
        ),
        Switch(
          value: useDpad,
          onChanged: (val) async {
            setState(() => useDpad = val);
            await SettingsService().setUseDpad(val);
          },
          activeColor: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildDropdownRow(
    String label,
    List<String> options,
    String value,
    void Function(String?) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontFamily: 'Ithica'),
        ),
        DropdownButton<String>(
          value: value,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white, fontFamily: 'Ithica'),
          items:
              options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSliderRow(
    String label,
    double value,
    void Function(double) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Ithica',
            fontSize: 24,
          ),
        ),
        Expanded(
          child: Slider(
            thumbColor: Colors.white,
            activeColor: Colors.white,
            overlayColor: MaterialStateProperty.all(Colors.white),
            inactiveColor: Colors.white,
            value: value,
            onChanged: onChanged,
            min: label == 'Font Size' ? 10 : 0,
            max: label == 'Font Size' ? 32 : 1,
            divisions: label == 'Font Size' ? 11 : 10,
            label:
                label == 'Font Size'
                    ? value.round().toString()
                    : '${(value * 100).round()}%',
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.transparent),
        foregroundColor: MaterialStateProperty.all(Colors.transparent),
        elevation: MaterialStateProperty.all(0.0),
      ),
      onPressed: () {
        print('pressed');
        widget.game.returnToStartMenu();
      },
      child: const Text(
        'Back',
        style: TextStyle(
          fontFamily: 'Ithica',
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  void _triggerSelectedItem() {
    if (selectedIndex < _keyRowKeys.length) {
      final key = _keyRowKeys[selectedIndex];
      key.currentState?.startListeningExternally();
      return;
    }

    switch (selectedIndex) {
      case 8:
        if (Platform.isAndroid) {
          setState(() => useDpad = !useDpad);
          SettingsService().setUseDpad(useDpad);
        }
        break;
      case 9:
      case 10:
        break;
      case 11:
        break;
      case 12:
        if (!Platform.isAndroid) {
          widget.game.overlays.remove('SettingsMenu');
          widget.game.playerIsInSettingsMenu = false;
          widget.game.playerIsInMenu = true;
          widget.game.overlays.add('StartMenu');
          widget.game.keyboardListenerKey.currentState?.regainFocus();
          widget.game.resumeEngine();
        }
        break;
      case 13:
        widget.game.overlays.remove('SettingsMenu');
        widget.game.overlays.remove('TouchControls');
        widget.game.playerIsInSettingsMenu = false;
        widget.game.playerIsInMenu = true;
        widget.game.overlays.add('StartMenu');
        widget.game.keyboardListenerKey.currentState?.regainFocus();
        widget.game.ensureTouchControls();
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

    final settingsItems = <Widget>[
      // _buildK+eyRow('Start Battle', 'Battle', _keyRowKeys[2]),
      _buildKeyRow('Move Up', 'MoveUp', _keyRowKeys[0]),
      _buildKeyRow('Move Down', 'MoveDown', _keyRowKeys[1]),
      _buildKeyRow('Move Left', 'MoveLeft', _keyRowKeys[2]),
      _buildKeyRow('Move Right', 'MoveRight', _keyRowKeys[3]),
      _buildKeyRow('Action Button', 'Action', _keyRowKeys[4]),
      _buildKeyRow('Back', 'Back', _keyRowKeys[5]),
      _buildKeyRow('Pause', 'Pause', _keyRowKeys[6]),
      if (Platform.isAndroid) _buildSwitchRow('Use D-pad'),
      carouselSetting(
        label: 'Difficulty',
        value: difficulty,
        options: difficultyOptions,
        onChanged: (v) => setState(() => difficulty = v),
      ),

      carouselSetting(
        label: 'Resolution',
        options: resolutionOptions,
        value: resolution,
        onChanged: (v) async {
          print(v);
          await settings.setResolution(v);
          widget.game.camera.viewport = FixedResolutionViewport(
            resolution: settings.resolutionToVector(v),
          );
          setState(() => resolution = v);
        },
      ),

      _buildSliderRow('Volume', volume, (v) => setState(() => volume = v)),
      _buildSliderRow(
        'Font Size',
        fontSize,
        (v) => setState(() => fontSize = v),
      ),
      _buildBackButton(),
    ];

    _totalItems = settingsItems.length;

    return Stack(
      children: [
        Material(
          color: Colors.black.withOpacity(0.95),
          child: Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: Column(
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Ithica',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: settingsItems.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == selectedIndex;
                        return Container(
                          decoration:
                              isSelected
                                  ? BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                  : null,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(4),
                          child: settingsItems[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
