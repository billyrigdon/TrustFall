import 'dart:async';
import 'dart:convert';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/game/characters/enemies/test_enemy.dart';
import 'package:game/models/equipment.dart';
import 'package:game/models/party_member.dart';
import 'package:game/models/items.dart';
import 'package:game/main.dart';
import 'package:game/models/attacks.dart';
import 'package:game/models/character_stats.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/wall.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPlayer extends SpriteAnimationComponent
    with KeyboardHandler, CollisionCallbacks, HasGameRef<TrustFall>
    implements BattleCharacter {
  final double speed = 100.0;
  Vector2 moveDirection = Vector2.zero();
  Vector2 _lastSafePosition = Vector2.zero();
  String lastDirection = 'down';

  @override
  late List<Attack> attacks;

  @override
  late CharacterStats stats;

  @override
  int currentHP = 0;

  @override
  String name = "Main Player";

  late SpriteAnimation idleRight;
  late SpriteAnimation idleDown;
  late SpriteAnimation idleLeft;
  late SpriteAnimation idleUp;
  late SpriteAnimation idleAnimation;
  late SpriteAnimation walkUp;
  late SpriteAnimation walkDown;
  late SpriteAnimation walkLeft;
  late SpriteAnimation walkRight;
  late SpriteAnimation walkUpRight;
  late SpriteAnimation walkUpLeft;
  late SpriteAnimation walkDownLeft;
  late SpriteAnimation walkDownRight;

  late SpriteAnimation diagAnimation;

  final settings = SettingsService();
  StreamSubscription<GamepadEvent>? _gamepadSub;
  final Set<String> _activeInputs = {};

  MainPlayer() : super(size: Vector2(40, 60), anchor: Anchor.topLeft);

  Future<void> _loadHPFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    currentHP = prefs.getInt('$name-hp') ?? stats.maxHp.toInt();
  }

  Future<void> _saveHPToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$name-hp', currentHP);
  }

  @override
  Future<void> onLoad() async {
    // debugMode = true;

    await settings.load();

    add(
      RectangleHitbox.relative(
        Vector2(1, 0.5),
        parentSize: size,
        position: Vector2(1, 40),
        anchor: Anchor.topLeft,
      )..collisionType = CollisionType.active,
    );

    idleRight = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_right_1.png'),
    ], stepTime: 1.0);

    idleUp = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_up_1.png'),
    ], stepTime: 1.0);

    idleDown = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_bottom_1.png'),
    ], stepTime: 1.0);

    idleLeft = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_left_1.png'),
    ], stepTime: 1.0);

    walkRight = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_right_1.png'),
      // await gameRef.loadSprite('main_right_2.png'),
    ], stepTime: 0.2);

    walkLeft = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_left_1.png'),
      // await gameRef.loadSprite('main_left_2.png'),
    ], stepTime: 0.2);

    walkUp = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_up_1.png'),
      await gameRef.loadSprite('main_up_2.png'),
    ], stepTime: 0.2);

    walkDown = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_bottom_1.png'),
      await gameRef.loadSprite('main_bottom_2.png'),
    ], stepTime: 0.2);

    walkUpRight = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_top_right_1.png'),
      // await gameRef.loadSprite('main_up_right_2.png'),
    ], stepTime: 0.2);

    walkUpLeft = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_top_left_1.png'),
      // await gameRef.loadSprite('main_up_left_2.png'),
    ], stepTime: 0.2);

    walkDownRight = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_bottom_right_1.png'),
      // await gameRef.loadSprite('main_down_right_2.png'),
    ], stepTime: 0.2);

    walkDownLeft = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_bottom_left_1.png'),
      // await gameRef.loadSprite('main_down_left_2.png'),
    ], stepTime: 0.2);

    idleAnimation = idleDown;

    stats = await CharacterStats.load(name, CharacterClass.balanced);

    await _loadHPFromPrefs();
    await loadInventory();
    await loadAttacks();
    await loadParty();
    handleMoving(1);
  }

  List<Attack> _defaultAttacks() => [
    Attack(name: 'Kick', type: AttackType.physical, power: 1.0),
    Attack(name: 'Charm', type: AttackType.mental, power: 1.2),
  ];

  @override
  Future<void> loadAttacks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$name-attacks');

    if (raw == null || raw.isEmpty) {
      attacks = _defaultAttacks();
      await saveAttacks();
    } else {
      attacks =
          raw
              .map(
                (str) =>
                    Attack.fromJson(Map<String, dynamic>.from(jsonDecode(str))),
              )
              .toList();
    }
  }

  @override
  Future<void> saveAttacks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = attacks.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('$name-attacks', list);
  }

  @override
  void learnAttack(Attack attack) {
    if (!attacks.any((a) => a.name == attack.name)) {
      attacks.add(attack);
      saveAttacks();
    }
  }

  handleMoving(double? dt) {
    moveDirection = Vector2.zero();

    final up = settings.getBinding('MoveUp');
    final down = settings.getBinding('MoveDown');
    final left = settings.getBinding('MoveLeft');
    final right = settings.getBinding('MoveRight');

    final pressingUp = _checkInput(up, ['Arrow Up', 'W', 'w']);
    final pressingDown = _checkInput(down, ['Arrow Down', 'S', 's']);
    final pressingLeft = _checkInput(left, ['Arrow Left', 'A', 'a']);
    final pressingRight = _checkInput(right, ['Arrow Right', 'D', 'd']);

    if (pressingUp) moveDirection.y -= 1;
    if (pressingDown) moveDirection.y += 1;
    if (pressingLeft) moveDirection.x -= 1;
    if (pressingRight) moveDirection.x += 1;

    if (moveDirection.x > 0 && moveDirection.y < 0) {
      lastDirection = 'upRight';
      animation = walkUpRight;
    } else if (moveDirection.x < 0 && moveDirection.y < 0) {
      lastDirection = 'upLeft';
      animation = walkUpLeft;
    } else if (moveDirection.x > 0 && moveDirection.y > 0) {
      lastDirection = 'downRight';
      animation = walkDownRight;
    } else if (moveDirection.x < 0 && moveDirection.y > 0) {
      lastDirection = 'downLeft';
      animation = walkDownLeft;
    } else if (moveDirection.x > 0) {
      lastDirection = 'right';
      animation = walkRight;
    } else if (moveDirection.x < 0) {
      lastDirection = 'left';
      animation = walkLeft;
    } else if (moveDirection.y > 0) {
      lastDirection = 'down';
      animation = walkDown;
    } else if (moveDirection.y < 0) {
      lastDirection = 'up';
      animation = walkUp;
    }

    if (moveDirection.length > 0 && dt != null) {
      _lastSafePosition = position.clone();
      moveDirection.normalize();
      position += moveDirection * speed * dt;
    } else {
      // 😌 Idle animations based on last direction
      switch (lastDirection) {
        case 'left':
          animation = idleLeft;
          break;
        case 'right':
          animation = idleRight;
          break;
        case 'up':
          animation = idleUp;
          break;
        case 'down':
        default:
          animation = idleDown;
          break;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    handleMoving(dt);
    // print(dt);
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is Wall) {
      position = _lastSafePosition;
    }
  }

  @override
  void onRemove() {
    _gamepadSub?.cancel();
    super.onRemove();
  }

  bool _checkInput(String binding, List<String> fallbacks) {
    return _activeInputs.contains(binding) ||
        fallbacks.any(_activeInputs.contains);
  }

  @override
  void takeDamage(int damage) {
    currentHP = (currentHP - damage).clamp(0, stats.maxHp.toInt());
    _saveHPToPrefs();

    if (currentHP <= 0) {
      gameRef.endBattle(); // This assumes you have such a method
    }
  }

  @override
  void heal(int amount) {
    currentHP = (currentHP + amount).clamp(0, stats.maxHp.toInt());
    _saveHPToPrefs();
  }

  @override
  void gainXpFromEnemy({required double baseXp, required int enemyLevel}) {
    final levelDiff = enemyLevel - stats.level;
    final modifier = 1.0 + (levelDiff * 0.1);
    stats.gainXP(baseXp * modifier.clamp(0.5, 2.0), id: name);
    // You could persist level/xp here too later
  }

  @override
  bool get isAlive => currentHP > 0;

  @override
  List<Item> inventory = [];

  Future<void> loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$name-inventory');

    if (raw == null || raw.isEmpty) {
      inventory = [
        Item(
          name: 'Cookie',
          type: ItemType.food,
          damage: 1,
          price: 5,
          value: 50,
        ),
        Item(name: 'Stabilizer', type: ItemType.medicine, damage: 1, price: 10),
        Item(name: 'Toy', type: ItemType.keyItem, damage: 3, price: 5),
        Item(name: 'Plushie', type: ItemType.keyItem, damage: 1, price: 15),
        Item(name: 'Trinket', type: ItemType.keyItem, damage: 3, price: 100),
        Equipment(
          name: 'Shoes',
          slot: EquipmentSlot.footwear,
          damage: 5,
          price: 25,
        ),
      ];
    } else {
      inventory =
          raw.map((str) {
            final json = Map<String, dynamic>.from(jsonDecode(str));
            return json['slot'] != null
                ? Equipment.fromJson(json)
                : Item.fromJson(json);
          }).toList();
    }

    final existingCurrency = inventory.firstWhere(
      (item) => item.type == ItemType.currency,
      orElse:
          () =>
              Item(name: 'Money', type: ItemType.currency, damage: 0, value: 0),
    );

    inventory.removeWhere((item) => item.type == ItemType.currency);
    inventory.insert(0, existingCurrency); // Ensure it's always the first item

    await saveInventory();
  }

  Future<void> saveInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = inventory.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('$name-inventory', data);
  }

  @override
  void addItem(Item item) {
    inventory.add(item);
    saveInventory();
  }

  @override
  void removeItem(Item item) {
    inventory.removeWhere((i) => i.name == item.name);
    saveInventory();
  }

  int get money {
    final bits = inventory.firstWhere(
      (item) => item.type == ItemType.currency,
      orElse:
          () =>
              Item(name: 'Bits', type: ItemType.currency, damage: 0, value: 0),
    );
    return bits.value ?? 0;
  }

  set money(int amount) {
    final index = inventory.indexWhere(
      (item) => item.type == ItemType.currency,
    );
    if (index != -1) {
      final bits = inventory[index];
      inventory[index] = Item(
        name: bits.name,
        type: bits.type,
        damage: 0,
        value: amount,
      );
      saveInventory();
    }
  }

  @override
  Future<void> loadHP() async {
    final prefs = await SharedPreferences.getInstance();
    currentHP = prefs.getInt('$name-hp') ?? stats.maxHp.toInt();
  }

  @override
  Future<void> saveHP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$name-hp', currentHP);
  }

  void handleTouchInput(String label, bool isPressed) {
    if (isPressed) {
      _activeInputs.add(label);
    } else {
      _activeInputs.remove(label);
    }
  }

  @override
  List<PartyMember> currentParty = [];

  @override
  void addToParty(PartyMember member) {
    if (!currentParty.any((m) => m.name == member.name)) {
      currentParty.add(member);
      saveParty();
    }
  }

  @override
  void clearParty() {
    currentParty.clear();
    saveParty();
  }

  @override
  Future<void> loadParty() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('$name-party') ?? [];

    currentParty =
        rawList.map((jsonStr) {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          return PartyMember.fromJson(data);
        }).toList();
  }

  @override
  void removeFromParty(String name) {
    currentParty.removeWhere((m) => m.name == name);
    saveParty();
  }

  @override
  Future<void> saveParty() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        currentParty.map((member) => jsonEncode(member.toJson())).toList();
    await prefs.setStringList('$name-party', jsonList);
  }
}
