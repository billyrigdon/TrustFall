import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game/models/battle_status.dart';
import 'package:game/models/can_act_result.dart';
import 'package:game/models/enemy.dart';
import 'package:game/models/battle_character.dart';
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
  late List<Attack> bank;

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
  // late SpriteAnimation walkUpRight;
  // late SpriteAnimation walkUpLeft;
  // late SpriteAnimation walkDownLeft;
  // late SpriteAnimation walkDownRight;

  // late SpriteAnimation diagAnimation;

  final settings = SettingsService();
  StreamSubscription<GamepadEvent>? _gamepadSub;
  final Set<String> _activeInputs = {};

  MainPlayer() : super(size: Vector2(30, 60), anchor: Anchor.topLeft);

  void clearInputs() {
    _activeInputs.clear();
  }

  Future<void> _loadHPFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    currentHP = prefs.getInt('$name-hp') ?? stats.maxHp.toInt();
  }

  Future<void> _saveHPToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$name-hp', currentHP);
  }

  Future<void> _loadMPFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    currentMP = prefs.getInt('$name-mp') ?? stats.maxMP.toInt();
  }

  Future<void> _saveMPToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$name-mp', currentMP);
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
      await gameRef.loadSprite('main_player_idle_right.png'),
    ], stepTime: 1.0);

    idleUp = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_player_back_1.png'),
    ], stepTime: 1.0);

    idleDown = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_player_front_1.png'),
    ], stepTime: 1.0);

    idleLeft = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_player_idle_left.png'),
    ], stepTime: 1.0);

    walkRight = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_player_1.png'),
      await gameRef.loadSprite('main_player_2.png'),
      await gameRef.loadSprite('main_player_3.png'),
      await gameRef.loadSprite('main_player_4.png'),
      await gameRef.loadSprite('main_player_5.png'),
      await gameRef.loadSprite('main_player_6.png'),
      await gameRef.loadSprite('main_player_7.png'),
    ], stepTime: 0.15);

    walkLeft = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_player_left_1.png'),
      await gameRef.loadSprite('main_player_left_2.png'),
      await gameRef.loadSprite('main_player_left_3.png'),
      await gameRef.loadSprite('main_player_left_4.png'),
      await gameRef.loadSprite('main_player_left_5.png'),
      await gameRef.loadSprite('main_player_left_6.png'),
      await gameRef.loadSprite('main_player_left_7.png'),
    ], stepTime: 0.15);

    walkUp = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_player_back_1.png'),
      await gameRef.loadSprite('main_player_back_2.png'),
      await gameRef.loadSprite('main_player_back_3.png'),
      await gameRef.loadSprite('main_player_back_4.png'),
      await gameRef.loadSprite('main_player_back_5.png'),
      await gameRef.loadSprite('main_player_back_6.png'),
    ], stepTime: 0.15);

    walkDown = SpriteAnimation.spriteList([
      await gameRef.loadSprite('main_player_front_1.png'),
      await gameRef.loadSprite('main_player_front_2.png'),
      await gameRef.loadSprite('main_player_front_3.png'),
      await gameRef.loadSprite('main_player_front_4.png'),
      await gameRef.loadSprite('main_player_front_5.png'),
      await gameRef.loadSprite('main_player_front_6.png'),
    ], stepTime: 0.15);

    // walkUpRight = SpriteAnimation.spriteList([
    //   await gameRef.loadSprite('main_top_right_1.png'),
    //   // await gameRef.loadSprite('main_up_right_2.png'),
    // ], stepTime: 0.2);

    // walkUpLeft = SpriteAnimation.spriteList([
    //   await gameRef.loadSprite('main_top_left_1.png'),
    //   // await gameRef.loadSprite('main_up_left_2.png'),
    // ], stepTime: 0.2);

    // walkDownRight = SpriteAnimation.spriteList([
    //   await gameRef.loadSprite('main_bottom_right_1.png'),
    //   // await gameRef.loadSprite('main_down_right_2.png'),
    // ], stepTime: 0.2);

    // walkDownLeft = SpriteAnimation.spriteList([
    //   await gameRef.loadSprite('main_bottom_left_1.png'),
    //   // await gameRef.loadSprite('main_down_left_2.png'),
    // ], stepTime: 0.2);

    idleAnimation = idleDown;

    stats = await CharacterStats.load(name, CharacterClass.balanced);

    await _loadHPFromPrefs();
    await _loadMPFromPrefs();
    await loadInventory();
    await loadAttacks();
    await loadBank();
    await loadParty();
    await loadEquipment();
    await assignStarterEquipmentIfNeeded();
  }

  List<Attack> _defaultAttacks() => [
    Attack(name: 'Kick', type: AttackType.physical, power: 1.0),
    Attack(name: 'Charm', type: AttackType.physical, power: 1.2),
  ];

  List<Attack> _defaultBank() => [
    Attack(
      name: 'Insult',
      type: AttackType.mental,
      cost: 20,
      power: 1.0,
      statusEffect: BattleStatusType.rage,
      statusDuration: 2,
    ),
    Attack(
      name: 'Manipulate',
      type: AttackType.mental,
      cost: 40,
      power: 10,
      statusEffect: BattleStatusType.confused,
      statusDuration: 3,
    ),
    Attack(
      name: 'Gaslight',
      type: AttackType.mental,
      cost: 35,
      power: 1.2,
      statusEffect: BattleStatusType.selfDoubt,
      statusDuration: 3,
    ),
    Attack(
      name: 'Fake Compliment',
      type: AttackType.mental,
      cost: 25,
      power: 0.5,
      statusEffect: BattleStatusType.charmed,
      statusDuration: 2,
    ),
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
  Future<void> loadBank() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$name-bank-moves');

    if (raw == null || raw.isEmpty) {
      bank = _defaultBank();
      await saveBank();
    } else {
      bank =
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
  Future<void> saveBank() async {
    final prefs = await SharedPreferences.getInstance();
    final list = bank.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('$name-bank-moves', list);
  }

  @override
  void learnAttack(Attack attack) {
    if (!attacks.any((a) => a.name == attack.name)) {
      attacks.add(attack);
      saveAttacks();
    }
  }

  @override
  void learnBankMove(Attack attack) {
    if (!bank.any((a) => a.name == attack.name)) {
      bank.add(attack);
      saveBank();
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

    // if (moveDirection.x > 0 && moveDirection.y < 0) {
    //   lastDirection = 'upRight';
    //   animation = walkUpRight;
    // } else if (moveDirection.x < 0 && moveDirection.y < 0) {
    //   lastDirection = 'upLeft';
    //   animation = walkUpLeft;
    // } else if (moveDirection.x > 0 && moveDirection.y > 0) {
    //   lastDirection = 'downRight';
    //   animation = walkDownRight;
    // } else if (moveDirection.x < 0 && moveDirection.y > 0) {
    //   lastDirection = 'downLeft';
    //   animation = walkDownLeft;
    // } else
    if (moveDirection.x > 0) {
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

  final Map<EquipmentSlot, Equipment?> equipped = {
    for (var slot in EquipmentSlot.values) slot: null,
  };

  int get totalDefense {
    final gearBonus = equipped.values.whereType<Equipment>().fold<int>(
      0,
      (sum, eq) => sum + eq.defense,
    );
    return stats.defense.toInt() + gearBonus;
  }

  int get totalIntelligence {
    final gearBonus = equipped.values.whereType<Equipment>().fold<int>(
      0,
      (sum, eq) => sum + eq.intelligence,
    );
    return stats.intelligence.toInt() + gearBonus;
  }

  double get totalDamage {
    final weapon = equipped[EquipmentSlot.weapon];
    return stats.strength.toInt() + (weapon?.damage ?? 0);
  }

  bool equip(Equipment item) {
    if (item.slot == null) return false;
    equipped[item.slot] = item;
    return true;
  }

  void unequip(EquipmentSlot slot) {
    equipped[slot] = null;
  }

  Future<void> saveEquipment() async {
    final prefs = await SharedPreferences.getInstance();
    final map = equipped.map(
      (slot, item) => MapEntry(
        slot.toString().split('.').last,
        item != null ? jsonEncode(item.toJson()) : '',
      ),
    );
    await prefs.setString('$name-equipment', jsonEncode(map));
  }

  Future<void> loadEquipment() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$name-equipment');
    if (raw == null) return;

    final Map<String, dynamic> jsonMap = jsonDecode(raw);
    for (final entry in jsonMap.entries) {
      final slot = equipmentSlotFromString(entry.key);
      final data = entry.value;
      equipped[slot] =
          data.isNotEmpty ? Equipment.fromJson(jsonDecode(data)) : null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.inBattle) {
      moveDirection = Vector2.zero();
      return;
    }

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
          spriteAsset: '',
          damage: 1,
          price: 5,
          value: 50,
        ),
        Item(
          name: 'Stabilizer',
          spriteAsset: '',
          type: ItemType.medicine,
          damage: 1,
          price: 10,
        ),
        Item(
          name: 'Toy',
          spriteAsset: '',
          type: ItemType.keyItem,
          damage: 3,
          price: 5,
        ),
        Item(
          name: 'Plushie',
          spriteAsset: '',
          type: ItemType.keyItem,
          damage: 1,
          price: 15,
        ),
        Item(
          name: 'Trinket',
          spriteAsset: '',
          type: ItemType.keyItem,
          damage: 3,
          price: 100,
        ),
        Item(
          name: 'Stabilizer',
          spriteAsset: '',
          type: ItemType.medicine,
          damage: 1,
          price: 10,
        ),
        Item(
          name: 'Toy',
          spriteAsset: '',
          type: ItemType.keyItem,
          damage: 3,
          price: 5,
        ),
        Item(
          name: 'Plushie',
          spriteAsset: '',
          type: ItemType.keyItem,
          damage: 1,
          price: 15,
        ),
        Item(
          name: 'Trinket',
          spriteAsset: '',
          type: ItemType.keyItem,
          damage: 3,
          price: 100,
        ),
        Equipment(
          name: 'Rusty Fork',
          slot: EquipmentSlot.weapon,
          damage: 5,
          price: 25,
        ),
        Equipment(
          name: 'Shoes',
          slot: EquipmentSlot.footwear,
          damage: 5,
          price: 25,
        ),
        Equipment(
          name: 'T-shirt',
          slot: EquipmentSlot.clothes,
          defense: 2,
          price: 10,
        ),
        Equipment(
          name: 'Charm Bracelet',
          slot: EquipmentSlot.accessory,
          intelligence: 3,
          price: 30,
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
          () => Item(
            name: 'Money',
            spriteAsset: '',
            type: ItemType.currency,
            damage: 0,
            value: 0,
          ),
    );

    inventory.removeWhere((item) => item.type == ItemType.currency);
    inventory.insert(0, existingCurrency); // Ensure it's always the first item

    await saveInventory();
  }

  Future<void> assignStarterEquipmentIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasStarterEquipment =
        prefs.getBool('$name-starter-equipment') ?? false;

    if (hasStarterEquipment) return; // already assigned once

    for (final slot in EquipmentSlot.values) {
      if (equipped[slot] == null) {
        final fallback = inventory.whereType<Equipment>().firstWhere(
          (e) => ((e.slot) == slot),
        );

        if (fallback != null) {
          equip(fallback);
          removeItem(fallback);
        }
      }
    }

    await saveEquipment();
    await prefs.setBool('$name-starter-equipment', true);
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
          () => Item(
            name: 'Bits',
            spriteAsset: '',
            type: ItemType.currency,
            damage: 0,
            value: 0,
          ),
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
        spriteAsset: '',
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
      final action = settings.getBinding('Action');

      if (label == action || label == 'Enter') {
        print(label);
        // if (_checkInput(action, ['Enter', 'Space'])) {
        interact();
        // }
      }

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

  void interact() {
    final nearbyEnemy = gameRef.world.children.whereType<Enemy?>().firstWhere(
      (enemy) => enemy!.toRect().inflate(10).overlaps(toRect()),
      orElse: () => null,
    );

    if (nearbyEnemy != null) {
      nearbyEnemy.onInteract?.call();
      return;
    }

    final nearbyPartyMember = gameRef.world.children
        .whereType<PartyMember?>()
        .firstWhere(
          (member) => member!.toRect().inflate(10).overlaps(toRect()),
          orElse: () => null,
        );

    if (nearbyPartyMember != null) {
      nearbyPartyMember.onInteract?.call();
      return;
    }

    final nearbyItem = gameRef.world.children
        .whereType<ItemComponent?>()
        .firstWhere(
          (item) => item!.toRect().inflate(10).overlaps(toRect()),
          orElse: () => null,
        );

    if (nearbyItem != null) {
      nearbyItem.tryPickUp(position, toRect());
      return;
    }

    print('Nothing nearby');
  }

  @override
  Future<void> saveParty() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        currentParty.map((member) => jsonEncode(member.toJson())).toList();
    await prefs.setStringList('$name-party', jsonList);
  }

  @override
  double? bleed;

  @override
  Sprite? sprite;

  @override
  int currentMP = 0;

  final List<BattleStatus> statuses = [];

  bool hasStatus(BattleStatusType type) {
    return statuses.any((s) => s.type == type && s.duration > 0);
  }

  void applyStatus(BattleStatus status) {
    final existing = statuses.firstWhere(
      (s) => s.type == status.type,
      orElse: () => BattleStatus(type: status.type, duration: 0),
    );
    if (existing.duration == 0) {
      statuses.add(status);
    } else {
      existing.duration = max(existing.duration, status.duration);
    }
  }

  Future<CanActResult> canAct(
    Future<void> Function(String message, {bool requireConfirmation})
    showMessage,
  ) async {
    bool canAct = true;
    bool forceRandomTarget = false;
    bool forceAttack = false;
    bool blockSelfSupport = false;

    for (final status in statuses.where((s) => s.duration > 0)) {
      switch (status.type) {
        case BattleStatusType.stunned:
        case BattleStatusType.asleep:
          await showMessage('$name is ${status.type.name} and can’t act!');
          return CanActResult(canAct: false);
        case BattleStatusType.confused:
          forceRandomTarget = true;
          await showMessage('$name is confused...');
          break;
        case BattleStatusType.rage:
          forceAttack = true;
          await showMessage('$name is in a rage and must attack!');
          break;
        case BattleStatusType.selfDoubt:
          blockSelfSupport = true;
          await showMessage('$name is full of doubt...');
          break;
        case BattleStatusType.embarrassed:
          // 25% chance to skip turn
          if (Random().nextDouble() < 0.25) {
            await showMessage('$name is too embarrassed to act...');
            return CanActResult(canAct: false);
          }
          break;
        case BattleStatusType.charmed:
          // 50% chance to skip attacking the enemy
          if (Random().nextDouble() < 0.5) {
            await showMessage('$name is charmed and refuses to attack!');
            return CanActResult(canAct: false);
          }
          break;
      }
    }

    return CanActResult(
      canAct: canAct,
      forceRandomTarget: forceRandomTarget,
      forceAttack: forceAttack,
      blockSelfSupport: blockSelfSupport,
    );
  }

  void decrementStatuses() {
    for (final s in statuses) {
      if (s.duration > 0) s.duration--;
    }
  }
}
