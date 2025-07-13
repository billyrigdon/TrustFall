import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/main.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/keybinding_row.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final service = SettingsService(); // Reuse the singleton instance
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 400,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Settings',
                style: TextStyle(color: Colors.amber, fontSize: 24),
              ),
              const SizedBox(height: 20),

              KeyBindingRow(
                label: 'Talk',
                action: 'Talk',
                currentBinding: keyBindings['Talk'],
                onBind: (key) async {
                  await SettingsService().bindAction('Talk', key);
                  setState(() => keyBindings['Talk'] = key);
                },
              ),
              KeyBindingRow(
                label: 'Pause',
                action: 'Pause',
                currentBinding: keyBindings['Pause'],
                onBind: (key) async {
                  await SettingsService().bindAction('Pause', key);
                  setState(() => keyBindings['Pause'] = key);
                },
              ),
              KeyBindingRow(
                label: 'Start Battle',
                action: 'Battle',
                currentBinding: keyBindings['Battle'],
                onBind: (key) async {
                  await SettingsService().bindAction('Battle', key);
                  setState(() => keyBindings['Battle'] = key);
                },
              ),

              KeyBindingRow(
                label: 'Move Up',
                action: 'MoveUp',
                currentBinding: keyBindings['MoveUp'],
                onBind: (key) async {
                  await SettingsService().bindAction('MoveUp', key);
                  setState(() => keyBindings['MoveUp'] = key);
                },
              ),
              KeyBindingRow(
                label: 'Move Down',
                action: 'MoveDown',
                currentBinding: keyBindings['MoveDown'],
                onBind: (key) async {
                  await SettingsService().bindAction('MoveDown', key);
                  setState(() => keyBindings['MoveDown'] = key);
                },
              ),
              KeyBindingRow(
                label: 'Move Left',
                action: 'MoveLeft',
                currentBinding: keyBindings['MoveLeft'],
                onBind: (key) async {
                  await SettingsService().bindAction('MoveLeft', key);
                  setState(() => keyBindings['MoveLeft'] = key);
                },
              ),
              KeyBindingRow(
                label: 'Move Right',
                action: 'MoveRight',
                currentBinding: keyBindings['MoveRight'],
                onBind: (key) async {
                  await SettingsService().bindAction('MoveRight', key);
                  setState(() => keyBindings['MoveRight'] = key);
                },
              ),
              KeyBindingRow(
                label: 'Action Button',
                action: 'Action',
                currentBinding: keyBindings['Action'],
                onBind: (key) async {
                  await SettingsService().bindAction('Action', key);
                  setState(() => keyBindings['Action'] = key);
                },
              ),

              dropdownSetting(
                label: 'Difficulty',
                value: difficulty,
                options: difficultyOptions,
                onChanged: (val) => setState(() => difficulty = val!),
              ),
              dropdownSetting(
                label: 'Resolution',
                value: resolution,
                options: resolutionOptions,
                onChanged: (val) => setState(() => resolution = val!),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Volume', style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      value: volume,
                      onChanged: (val) => setState(() => volume = val),
                      min: 0,
                      max: 1,
                      divisions: 10,
                      label: '${(volume * 100).round()}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Font Size',
                    style: TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: Slider(
                      value: fontSize,
                      onChanged: (val) => setState(() => fontSize = val),
                      min: 10,
                      max: 32,
                      divisions: 11,
                      label: '${fontSize.round()}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  widget.game.overlays.remove('SettingsMenu');
                  widget.game.overlays.add('StartMenu');
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
