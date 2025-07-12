// import 'package:shared_preferences/shared_preferences.dart';

// class SettingsService {
//   static const _volumeKey = 'volume';
//   static const _fontSizeKey = 'fontSize';
//   static const _difficultyKey = 'difficulty';
//   static const _controllerSchemeKey = 'controllerScheme';
//   static const _bindingPrefix = 'bind_';

//   late SharedPreferences _prefs;
//   bool _initialized = false;

//   double volume = 0.5;
//   double fontSize = 16.0;
//   String difficulty = 'Normal';
//   String controllerScheme = 'WASD';
//   final Map<String, String> _bindings = {};

//   Future<void> load() async {
//     _prefs = await SharedPreferences.getInstance();
//     _initialized = true;

//     volume = _prefs.getDouble(_volumeKey) ?? 0.5;
//     fontSize = _prefs.getDouble(_fontSizeKey) ?? 16.0;
//     difficulty = _prefs.getString(_difficultyKey) ?? 'Normal';
//     controllerScheme = _prefs.getString(_controllerSchemeKey) ?? 'WASD';

//     _bindings.clear();
//     for (var action in [
//       'MoveUp',
//       'MoveDown',
//       'MoveLeft',
//       'MoveRight',
//       'Action',
//     ]) {
//       final key = _prefs.getString('$_bindingPrefix$action');
//       if (key != null) {
//         _bindings[action] = key;
//       }
//     }
//   }

//   Future<void> save() async {
//     if (!_initialized) _prefs = await SharedPreferences.getInstance();

//     await _prefs.setDouble(_volumeKey, volume);
//     await _prefs.setDouble(_fontSizeKey, fontSize);
//     await _prefs.setString(_difficultyKey, difficulty);
//     await _prefs.setString(_controllerSchemeKey, controllerScheme);
//     for (var entry in _bindings.entries) {
//       await _prefs.setString('$_bindingPrefix${entry.key}', entry.value);
//     }
//   }

//   String getBinding(String action) {
//     return _bindings[action] ??
//         {
//           'MoveUp': 'Arrow Up',
//           'MoveDown': 'Arrow Down',
//           'MoveLeft': 'Arrow Left',
//           'MoveRight': 'Arrow Right',
//           'Action': 'Space',
//         }[action]!;
//   }

//   Future<void> bindAction(String action, String keyLabel) async {
//     if (!_initialized) _prefs = await SharedPreferences.getInstance();
//     _bindings[action] = keyLabel;
//     await _prefs.setString('$_bindingPrefix$action', keyLabel);
//   }

//   Future<Map<String, String>> getAllBindings() async {
//     if (!_initialized) _prefs = await SharedPreferences.getInstance();
//     return {
//       for (var action in [
//         'MoveUp',
//         'MoveDown',
//         'MoveLeft',
//         'MoveRight',
//         'Action',
//       ])
//         action:
//             _prefs.getString('$_bindingPrefix$action') ??
//             {
//               'MoveUp': 'Arrow Up',
//               'MoveDown': 'Arrow Down',
//               'MoveLeft': 'Arrow Left',
//               'MoveRight': 'Arrow Right',
//               'Action': 'Space',
//             }[action]!,
//     };
//   }
// }
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _volumeKey = 'volume';
  static const _fontSizeKey = 'fontSize';
  static const _difficultyKey = 'difficulty';
  static const _controllerSchemeKey = 'controllerScheme';
  static const _bindingPrefix = 'bind_';

  late SharedPreferences _prefs;
  bool _initialized = false;

  double volume = 0.5;
  double fontSize = 16.0;
  String difficulty = 'Normal';
  String controllerScheme = 'WASD';
  final Map<String, String> _bindings = {};

  final List<String> allActions = [
    'MoveUp',
    'MoveDown',
    'MoveLeft',
    'MoveRight',
    'Action',
    'Pause',
    'Battle',
    'Talk',
  ];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;

    volume = _prefs.getDouble(_volumeKey) ?? 0.5;
    fontSize = _prefs.getDouble(_fontSizeKey) ?? 16.0;
    difficulty = _prefs.getString(_difficultyKey) ?? 'Normal';
    controllerScheme = _prefs.getString(_controllerSchemeKey) ?? 'WASD';

    _bindings.clear();
    for (var action in allActions) {
      final key = _prefs.getString('$_bindingPrefix$action');
      if (key != null) {
        _bindings[action] = key;
      }
    }
  }

  Future<void> save() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }

    await _prefs.setDouble(_volumeKey, volume);
    await _prefs.setDouble(_fontSizeKey, fontSize);
    await _prefs.setString(_difficultyKey, difficulty);
    await _prefs.setString(_controllerSchemeKey, controllerScheme);

    for (var entry in _bindings.entries) {
      await _prefs.setString('$_bindingPrefix${entry.key}', entry.value);
    }
  }

  String getBinding(String action) {
    return _bindings[action] ??
        {
          'MoveUp': 'Arrow Up',
          'MoveDown': 'Arrow Down',
          'MoveLeft': 'Arrow Left',
          'MoveRight': 'Arrow Right',
          'Action': 'Enter',
          'Pause': 'Key P',
          'Battle': 'Key B',
          'Talk': 'Space',
        }[action]!;
  }

  Future<void> bindAction(String action, String keyLabel) async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }

    _bindings[action] = keyLabel;
    await _prefs.setString('$_bindingPrefix$action', keyLabel);
  }

  Future<Map<String, String>> getAllBindings() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }

    return {
      for (var action in allActions)
        action:
            _prefs.getString('$_bindingPrefix$action') ??
            {
              'MoveUp': 'Arrow Up',
              'MoveDown': 'Arrow Down',
              'MoveLeft': 'Arrow Left',
              'MoveRight': 'Arrow Right',
              'Action': 'Enter',
              'Pause': 'Key P',
              'Battle': 'Key B',
              'Talk': 'Space',
            }[action]!,
    };
  }
}
