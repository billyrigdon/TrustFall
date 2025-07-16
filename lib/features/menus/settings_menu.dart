import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/keybinding_row.dart';
import 'package:game/widgets/touch_overlay.dart';
import 'package:gamepads/gamepads.dart';

class SettingsMenu extends StatefulWidget {
  final TrustFall game;
  const SettingsMenu({super.key, required this.game});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  double volume = 0.5;
  double fontSize = 16.0;
  String controllerScheme = 'WASD';
  String difficulty = 'Normal';
  String resolution = '1280x720';
  final service = SettingsService(); //
  final List<FocusNode> _focusNodes = [];
  int selectedIndex = 0;
  bool isReady = false;
  // int focusIndex = 0;

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
    'Talk': null,
    'Pause': null,
    'Battle': null,
  };

  // bool isReady = false;
  // int selectedIndex = 0;
  int _totalItems = 0;

  final SettingsService settings = SettingsService();
  // Map<String, String?> keyBindings = {
  //   'MoveUp': null,
  //   'MoveDown': null,
  //   'MoveLeft': null,
  //   'MoveRight': null,
  //   'Action': null,
  //   'Talk': null,
  //   'Pause': null,
  //   'Battle': null,
  // };

  // double volume = 0.5;
  // double fontSize = 16.0;
  // String difficulty = 'Normal';
  // String resolution = '1280x720';
  bool useDpad = false;

  @override
  void initState() {
    super.initState();

    RawKeyboard.instance.addListener(_onKey);
    Gamepads.events.listen(_onGamepad);

    settings.load().then((_) {
      setState(() {
        for (var action in keyBindings.keys) {
          keyBindings[action] = settings.getBinding(action);
        }
        useDpad = settings.getUseDpad();
        isReady = true;
      });
    });
  }

  // void _handleInput(String inputLabel) {
  //   if (!isReady) return;

  //   final up = service.getBinding('MoveUp');
  //   final down = service.getBinding('MoveDown');
  //   final action = service.getBinding('Action');

  //   final isUp = inputLabel == up || inputLabel == 'Arrow Up';
  //   final isDown = inputLabel == down || inputLabel == 'Arrow Down';
  //   final isAction =
  //       inputLabel == action || inputLabel == 'Enter' || inputLabel == 'Space';

  //   if (isDown) {
  //     setState(() => selectedIndex = (selectedIndex + 1) % _totalItems);
  //   } else if (isUp) {
  //     setState(
  //       () => selectedIndex = (selectedIndex - 1 + _totalItems) % _totalItems,
  //     );
  //   } else if (isAction) {
  //     _triggerSelectedItem();
  //   }
  // }

  void _handleInput(String inputLabel) {
    if (!isReady) return;

    final up = service.getBinding('MoveUp');
    final down = service.getBinding('MoveDown');
    final action = service.getBinding('Action');

    final isUp = inputLabel == up || inputLabel == 'Arrow Up';
    final isDown = inputLabel == down || inputLabel == 'Arrow Down';
    final isAction =
        inputLabel == action ||
        inputLabel == 'Enter' ||
        inputLabel == LogicalKeyboardKey.enter.keyLabel ||
        inputLabel == 'A'; // ← from TouchControls

    if (isDown) {
      if (mounted)
        setState(() => selectedIndex = (selectedIndex + 1) % _totalItems);
    } else if (isUp) {
      if (mounted)
        setState(
          () => selectedIndex = (selectedIndex - 1 + _totalItems) % _totalItems,
        );
    } else if (isAction) {
      if (mounted) _triggerSelectedItem();
    }
  }

  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final keyLabel =
          event.logicalKey.keyLabel.isEmpty
              ? event.logicalKey.debugName ?? ''
              : event.logicalKey.keyLabel;
      print(keyLabel);
      _handleInput(keyLabel);
    }
  }

  void _onGamepad(GamepadEvent event) {
    if (event.value == 1.0 && event.type == KeyType.button) {
      final label = '${event.gamepadId}:${event.key}';
      _handleInput(label);
    } else if ((event.type.toString().contains('axis') ||
            event.type == KeyType.analog) &&
        event.value.abs() > 0.9) {
      final dir = event.value > 0 ? '+' : '-';
      final label = '${event.gamepadId}:${event.key}:$dir';
      _handleInput(label);
    }
  }

  // bool useDpad = false;

  void _loadSettings() async {
    await service.load();

    final actions = [
      'MoveUp',
      'MoveDown',
      'MoveLeft',
      'MoveRight',
      'Action',
      'Talk',
      'Pause',
      'Battle',
    ];

    setState(() {
      useDpad = service.getUseDpad();
      for (var action in actions) {
        keyBindings[action] = service.getBinding(action);
      }
    });
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
        Text(label, style: const TextStyle(color: Colors.white)),
        DropdownButton<String>(
          value: value,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          items:
              options.map((o) {
                return DropdownMenuItem(value: o, child: Text(o));
              }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  final List<GlobalKey<KeyBindingRowState>> _keyRowKeys = [
    GlobalKey(), // Talk
    GlobalKey(), // Pause
    GlobalKey(), // Battle
    GlobalKey(), // MoveUp
    GlobalKey(), // MoveDown
    GlobalKey(), // MoveLeft
    GlobalKey(), // MoveRight
    GlobalKey(), // Action
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
        Text(label, style: const TextStyle(color: Colors.white)),
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
        Text(label, style: const TextStyle(color: Colors.white)),
        DropdownButton<String>(
          value: value,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
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
        Text(label, style: const TextStyle(color: Colors.white)),
        Expanded(
          child: Slider(
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
      onPressed: () {
        widget.game.overlays.remove('SettingsMenu');
        widget.game.overlays.add('StartMenu');
      },
      child: const Text('Back'),
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
        // Dropdowns - possibly open later
        break;
      case 11:
        break;
      case 12:
        if (!Platform.isAndroid) {
          widget.game.overlays.remove('SettingsMenu');
          widget.game.overlays.add('StartMenu');
        }
        break;
      case 13:
        widget.game.overlays.remove('SettingsMenu');
        widget.game.overlays.add('StartMenu');
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
      _buildKeyRow('Talk', 'Talk', _keyRowKeys[0]),
      _buildKeyRow('Pause', 'Pause', _keyRowKeys[1]),
      _buildKeyRow('Start Battle', 'Battle', _keyRowKeys[2]),
      _buildKeyRow('Move Up', 'MoveUp', _keyRowKeys[3]),
      _buildKeyRow('Move Down', 'MoveDown', _keyRowKeys[4]),
      _buildKeyRow('Move Left', 'MoveLeft', _keyRowKeys[5]),
      _buildKeyRow('Move Right', 'MoveRight', _keyRowKeys[6]),
      _buildKeyRow('Action Button', 'Action', _keyRowKeys[7]),
      if (Platform.isAndroid) _buildSwitchRow('Use D-pad'),
      _buildDropdownRow(
        'Difficulty',
        difficultyOptions,
        difficulty,
        (v) => setState(() => difficulty = v!),
      ),
      _buildDropdownRow(
        'Resolution',
        resolutionOptions,
        resolution,
        (v) => setState(() => resolution = v!),
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
                    style: TextStyle(color: Colors.amber, fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: settingsItems.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == selectedIndex;
                        return Container(
                          decoration:
                              isSelected
                                  ? BoxDecoration(
                                    border: Border.all(
                                      color: Colors.amber,
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

        if (Platform.isAndroid || Platform.isIOS)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: TouchControls(
                onInput: (label, isPressed) {
                  if (isPressed) _handleInput(label);
                },
              ),
            ),
          ),
      ],
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   int focusIndex = 0;
  //   Widget buildFocusable(Widget child) {
  //     final node = _focusNodes[focusIndex+];
  //     return Focus(
  //       focusNode: node,
  //       onFocusChange: (_) => setState(() {}),
  //       child: GestureDetector(
  //         behavior: HitTestBehavior.opaque,
  //         onTap: () => node.requestFocus(),
  //         child: AnimatedContainer(
  //           duration: const Duration(milliseconds: 100),
  //           decoration: BoxDecoration(
  //             border:
  //                 node.hasFocus
  //                     ? Border.all(color: Colors.amberAccent, width: 2)
  //                     : null,
  //           ),
  //           child: child,
  //         ),
  //       ),
  //     );
  //   }

  //   return Material(
  //     color: Colors.black.withOpacity(0.95),
  //     child: Center(
  //       child: Container(
  //         padding: const EdgeInsets.all(16),
  //         width: 400,
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.white),
  //           borderRadius: BorderRadius.circular(12),
  //           color: Colors.black,
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Text(
  //               'Settings',
  //               style: TextStyle(color: Colors.amber, fontSize: 24),
  //             ),
  //             const SizedBox(height: 20),

  //             buildFocusable(
  //               KeyBindingRow(
  //                 label: 'Talk',
  //                 action: 'Talk',
  //                 currentBinding: keyBindings['Talk'],
  //                 onBind: (key) async {
  //                   await SettingsService().bindAction('Talk', key);
  //                   setState(() => keyBindings['Talk'] = key);
  //                 },
  //               ),
  //             ),
  //             buildFocusable(
  //               KeyBindingRow(
  //                 label: 'Pause',
  //                 action: 'Pause',
  //                 currentBinding: keyBindings['Pause'],
  //                 onBind: (key) async {
  //                   await SettingsService().bindAction('Pause', key);
  //                   setState(() => keyBindings['Pause'] = key);
  //                 },
  //               ),
  //             ),
  //             buildFocusable(
  //               KeyBindingRow(
  //                 label: 'Start Battle',
  //                 action: 'Battle',
  //                 currentBinding: keyBindings['Battle'],
  //                 onBind: (key) async {
  //                   await SettingsService().bindAction('Battle', key);
  //                   setState(() => keyBindings['Battle'] = key);
  //                 },
  //               ),
  //             ),

  //             buildFocusable(
  //               KeyBindingRow(
  //                 label: 'Move Up',
  //                 action: 'MoveUp',
  //                 currentBinding: keyBindings['MoveUp'],
  //                 onBind: (key) async {
  //                   await SettingsService().bindAction('MoveUp', key);
  //                   setState(() => keyBindings['MoveUp'] = key);
  //                 },
  //               ),
  //             ),
  //             buildFocusable(
  //               KeyBindingRow(
  //                 label: 'Move Down',
  //                 action: 'MoveDown',
  //                 currentBinding: keyBindings['MoveDown'],
  //                 onBind: (key) async {
  //                   await SettingsService().bindAction('MoveDown', key);
  //                   setState(() => keyBindings['MoveDown'] = key);
  //                 },
  //               ),
  //             ),
  //             buildFocusable(
  //               KeyBindingRow(
  //                 label: 'Move Left',
  //                 action: 'MoveLeft',
  //                 currentBinding: keyBindings['MoveLeft'],
  //                 onBind: (key) async {
  //                   await SettingsService().bindAction('MoveLeft', key);
  //                   setState(() => keyBindings['MoveLeft'] = key);
  //                 },
  //               ),
  //             ),
  //             buildFocusable(
  //               KeyBindingRow(
  //                 label: 'Move Right',
  //                 action: 'MoveRight',
  //                 currentBinding: keyBindings['MoveRight'],
  //                 onBind: (key) async {
  //                   await SettingsService().bindAction('MoveRight', key);
  //                   setState(() => keyBindings['MoveRight'] = key);
  //                 },
  //               ),
  //             ),
  //             buildFocusable(
  //               KeyBindingRow(
  //                 label: 'Action Button',
  //                 action: 'Action',
  //                 currentBinding: keyBindings['Action'],
  //                 onBind: (key) async {
  //                   await SettingsService().bindAction('Action', key);
  //                   setState(() => keyBindings['Action'] = key);
  //                 },
  //               ),
  //             ),
  //             if (Platform.isAndroid)
  //               buildFocusable(
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     const Text(
  //                       'Use D-pad',
  //                       style: TextStyle(color: Colors.white),
  //                     ),
  //                     Switch(
  //                       value: useDpad,
  //                       activeColor: Colors.amber,
  //                       onChanged: (val) async {
  //                         setState(() => useDpad = val);
  //                         await SettingsService().setUseDpad(val);
  //                       },
  //                     ),
  //                   ],
  //                 ),
  //               ),

  //             buildFocusable(
  //               dropdownSetting(
  //                 label: 'Difficulty',
  //                 value: difficulty,
  //                 options: difficultyOptions,
  //                 onChanged: (val) => setState(() => difficulty = val!),
  //               ),
  //             ),
  //             buildFocusable(
  //               dropdownSetting(
  //                 label: 'Resolution',
  //                 value: resolution,
  //                 options: resolutionOptions,
  //                 onChanged: (val) => setState(() => resolution = val!),
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             buildFocusable(
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   const Text('Volume', style: TextStyle(color: Colors.white)),
  //                   Expanded(
  //                     child: Slider(
  //                       value: volume,
  //                       onChanged: (val) => setState(() => volume = val),
  //                       min: 0,
  //                       max: 1,
  //                       divisions: 10,
  //                       label: '${(volume * 100).round()}%',
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             buildFocusable(
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   const Text(
  //                     'Font Size',
  //                     style: TextStyle(color: Colors.white),
  //                   ),
  //                   Expanded(
  //                     child: Slider(
  //                       value: fontSize,
  //                       onChanged: (val) => setState(() => fontSize = val),
  //                       min: 10,
  //                       max: 32,
  //                       divisions: 11,
  //                       label: '${fontSize.round()}',
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             buildFocusable(
  //               ElevatedButton(
  //                 onPressed: () {
  //                   widget.game.overlays.remove('SettingsMenu');
  //                   widget.game.overlays.add('StartMenu');
  //                 },
  //                 child: const Text('Back'),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
