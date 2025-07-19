import 'dart:io';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:game/game/characters/character_list.dart';
import 'package:game/game/characters/enemies/ghost_enemy.dart';
import 'package:game/game/characters/enemies/test_enemy.dart';
import 'package:game/game/characters/main_player.dart';
import 'package:game/main.dart';
import 'package:game/game/scenes/main_player_house/main_player_house_room.dart';
import 'package:game/models/attacks.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/character_stats.dart';
import 'package:game/models/items.dart';
import 'package:game/models/party_member.dart';
import 'package:game/widgets/door.dart';
import 'package:game/widgets/wall.dart';

class MainPlayerHouse extends Component with HasGameRef<TrustFall> {
  final MainPlayerHouseRoom initialRoom;
  MainPlayerHouse(this.initialRoom);
  late NotifyingVector2 mapPixelSize;
  Vector2? doorSpawnCoordinates;
  final Map<String, Vector2> spawnPoints = {};
  String fromOrientation = '';

  @override
  Future<void> onLoad() async {
    debugMode = true;
    super.onLoad();
    await _loadRoom(
      initialRoom,
      previousPosition: Vector2.zero(),
      fromRoom: '',
    );
  }

  void _extractDoorSpawns(TiledComponent map) {
    final objectGroup = map.tileMap.getLayer<ObjectGroup>('Objects');
    if (objectGroup == null) return;

    for (final obj in objectGroup.objects) {
      final hasSpawn = obj.properties.any(
        (p) => p.name == 'spawn' && p.value == true,
      );

      if (hasSpawn) {
        final fromRoom =
            obj.properties.firstWhere((p) => p.name == 'fromRoom').value
                as String;

        final fromOrientation =
            obj.properties.firstWhere((p) => p.name == 'fromOrientation').value
                as String;

        final isSpecial = obj.properties.any(
          (p) => p.name == 'special_spawn' && p.value == true,
        );

        final key = '$fromRoom:$fromOrientation${isSpecial ? ':special' : ''}';
        spawnPoints[key] = Vector2(obj.x, obj.y);
      }
    }
  }

  // void _spawnRoomObjects(TiledComponent map) {
  //   final objectGroup = map.tileMap.getLayer<ObjectGroup>('Objects');

  //   for (final obj in objectGroup!.objects) {
  //     final isNpc = obj.properties.any(
  //       (p) => p.name == 'type' && p.value == 'npc',
  //     );
  //     final isEnemy = obj.properties.any(
  //       (p) => p.name == 'enemy' && p.value == true,
  //     );

  //     final isGhost = obj.properties.any(
  //       (p) => p.name == 'name' && p.value == 'ghost',
  //     );

  //     final isDude = obj.properties.any(
  //       (p) => p.name == 'name' && p.value == 'dude',
  //     );

  //     if (isNpc && isEnemy) {
  //       var enemy;
  //       if (isDude) {
  //         enemy = Enemy(
  //           name: 'Dude',
  //           level: 2,
  //           stats: CharacterStats(
  //             charClass: CharacterClass.balanced,
  //             maxHp: 60,
  //             strength: 1,
  //           ),
  //           spriteAsset: 'sprite.png',
  //           attacks: [
  //             Attack(name: 'Punch', type: AttackType.physical, power: 0.03),
  //           ],
  //         );
  //       } else if (isGhost) {
  //         enemy = Enemy(
  //           name: 'Ghost',
  //           level: 3,
  //           spriteAsset: 'ghost_enemy.png',
  //           stats: CharacterStats(
  //             charClass: CharacterClass.balanced,
  //             maxHp: 60,
  //             strength: 1,
  //           ),
  //           attacks: [
  //             Attack(name: 'Punch', type: AttackType.physical, power: 0.03),
  //           ],
  //         );
  //       }
  //       enemy.position = Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2);

  //       enemy.add(RectangleHitbox());
  // enemy.onInteract = () {
  //   if (_dialogOpen) return;
  //   _dialogOpen = true;
  //   gameRef.showDialogue(
  //     ['Hi there!', 'Do you want to fight?'],
  //     choices: ['Yes', 'No'],
  //     onChoiceSelected: (choice) {
  //       _dialogOpen = false;
  //       if (choice == 'Yes') {
  //         gameRef.startBattle([
  //           gameRef.player as BattleCharacter,
  //           ...(gameRef.player.currentParty
  //               .where((c) => c.name != gameRef.player.name)
  //               .toList()),
  //         ], enemy);
  //       }
  //     },
  //         );
  //       };

  //       gameRef.world.add(enemy);
  //     }
  //   }
  // }

  void _spawnRoomObjects(TiledComponent map) {
    final objectGroup = map.tileMap.getLayer<ObjectGroup>('Objects');
    // print(objectGroup!.objects.length);
    for (final obj in objectGroup!.objects) {
      print(obj.toString());
      print(obj.properties);
      final typeProp = obj.properties.firstWhere(
        (p) => p.name == 'type',
        orElse: () => Property(name: '', value: '', type: PropertyType.string),
      );

      final isEnemy = typeProp.value == 'enemy';
      final isPartyMember = typeProp.value == 'party_member';
      final isItem = typeProp.value == 'item';

      if (isItem) {
        final item = Item(
          name: 'toy',
          type: ItemType.keyItem,
          damage: 3,
          value: 10,
          price: 50,
          spriteAsset: 'toy_item.png',
        );

        final itemComponent = ItemComponent(
          item: item,
          position: Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2),
        );

        gameRef.world.add(itemComponent);
        continue;
      }

      final idProp = obj.properties.firstWhere(
        (p) => p.name == 'characterId',
        orElse: () => Property(name: '', value: '', type: PropertyType.string),
      );

      final id = idProp.value.toString();
      final definition =
          MainPlayerHouseCharacterDefinitions(
            gameRef: gameRef,
          ).getCharacters()[id];

      if (definition == null) {
        // print('Character ID "$id" not found in enemyDefinitions');
        continue;
      }

      final position = Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2);
      definition.position = position;
      definition.add(RectangleHitbox());

      if (isEnemy && definition is Enemy) {
        // Use optional pre-defined behavior, or assign generic battle trigger
        // definition.

        gameRef.world.add(definition);
      } else if (isPartyMember && definition is PartyMember) {
        gameRef.world.add(definition);
      }
    }
  }

  // void _spawnRoomObjects(TiledComponent map) {
  //   final objectGroup = map.tileMap.getLayer<ObjectGroup>('Objects');

  //   for (final obj in objectGroup!.objects) {
  //     final isNpc = obj.properties.any(
  //       (p) => p.name == 'type' && p.value == 'npc',
  //     );
  //     final isEnemy = obj.properties.any(
  //       (p) => p.name == 'enemy' && p.value == true,
  //     );

  //     final isGhost = obj.properties.any(
  //       (p) => p.name == 'name' && p.value == 'ghost',
  //     );

  //     final isDude = obj.properties.any(
  //       (p) => p.name == 'name' && p.value == 'dude',
  //     );

  //     final isItem = obj.properties.any(
  //       (p) => p.name == 'type' && p.value == 'item',
  //     );

  //     //TODO: pull properties from json/tiled
  //     if (isItem) {
  //       Item item = Item(
  //         name: 'toy',
  //         type: ItemType.keyItem,
  //         damage: 3,
  //         value: 10,
  //         price: 50,
  //         spriteAsset: 'toy_item.png',
  //       );

  //       final itemComponent = ItemComponent(
  //         item: item,
  //         position: Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2),
  //       );

  //       gameRef.world.add(itemComponent);
  //     }

  //     if (isNpc && isEnemy) {
  //       Enemy enemy;

  //       if (isGhost) {
  //         enemy = Enemy(
  //           name: 'Ghost',
  //           level: 3,
  //           spriteAsset: 'ghost_enemy.png',
  //           stats: CharacterStats(
  //             charClass: CharacterClass.balanced,
  //             maxHp: 60,
  //             strength: 1,
  //           ),
  //           attacks: [
  //             Attack(name: 'Spook', type: AttackType.physical, power: 0.03),
  //           ],
  //         );
  //       } else {
  //         // Default to dude
  //         enemy = Enemy(
  //           name: 'Dude',
  //           level: 2,
  //           spriteAsset: 'sprite.png',
  //           stats: CharacterStats(
  //             charClass: CharacterClass.balanced,
  //             maxHp: 60,
  //             strength: 1,
  //           ),
  //           attacks: [
  //             Attack(name: 'Punch', type: AttackType.physical, power: 0.03),
  //           ],
  //         );
  //       }

  //       enemy.position = Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2);
  //       enemy.add(RectangleHitbox());

  //       if (isGhost) {
  //         // 👻 Ghost says boo then battles
  //         enemy.onInteract = () {
  //           if (_dialogOpen) return;
  //           _dialogOpen = true;

  //           gameRef.showDialogue(
  //             ['Boo!'],
  //             onComplete: () {
  //               _dialogOpen = false;
  //               print('starting battle');
  //               gameRef.startBattle([
  //                 gameRef.player as BattleCharacter,
  //                 ...(gameRef.player.currentParty
  //                     .where((c) => c.name != gameRef.player.name)
  //                     .toList()),
  //               ], enemy);
  //             },
  //           );
  //         };
  //       } else if (isDude) {
  //         // 🧍 Dude gives a choice
  //         enemy.onInteract = () {
  //           if (_dialogOpen) return;
  //           _dialogOpen = true;
  //           gameRef.showDialogue(
  //             ['Hi there!', 'Do you want to fight?'],
  //             choices: ['Yes', 'No'],
  //             onChoiceSelected: (choice) {
  //               _dialogOpen = false;
  //               if (choice == 'Yes') {
  //                 gameRef.startBattle([
  //                   gameRef.player as BattleCharacter,
  //                   ...gameRef.player.currentParty
  //                       .where((c) => c.name != gameRef.player.name)
  //                       .toList(),
  //                 ], enemy);
  //               }
  //             },
  //           );
  //         };
  //       }

  //       gameRef.world.add(enemy);
  //     }
  //   }
  // }

  Vector2 getSpawnPoint({
    required String fromRoom,
    required String orientation,
    required Vector2 userCoordinates,
  }) {
    final specialKey = '$fromRoom:$orientation:special';
    final normalKey = '$fromRoom:$orientation';
    if (spawnPoints.containsKey(specialKey)) {
      return spawnPoints[specialKey]!;
    }

    final doorSpawn = spawnPoints[normalKey] ?? Vector2.zero();

    if (orientation == 'vertical') {
      return Vector2(userCoordinates.x, doorSpawn.y);
    } else if (orientation == 'horizontal') {
      return Vector2(doorSpawn.x, userCoordinates.y);
    } else {
      return Vector2.zero();
    }
  }

  Future<void> _loadRoom(
    MainPlayerHouseRoom room, {
    required Vector2 previousPosition,
    String? orientation,
    required String fromRoom,
  }) async {
    final lastDirection = gameRef.player.lastDirection;
    final map = await TiledComponent.load(room.tmxFile, Vector2.all(32));
    fromOrientation = orientation ?? 'horizontal';
    gameRef.mapPixelSize = mapPixelSize = map.size;
    final world = World();
    gameRef.world = world;
    gameRef.add(world);
    world.add(map);

    // final viewportSize = gameRef.size; // This is your virtual resolution now!
    // final mapSize = mapPixelSize; // in pixels (like 640x480, 1280x720, etc.)

    // final scaleX = viewportSize.x / mapSize.x;
    // final scaleY = viewportSize.y / mapSize.y;

    // Choose the smaller scale so it fully fits
    // final scale = scaleX < scaleY ? scaleX : scaleY;

    // gameRef.camera.viewfinder.zoom = scale;

    final screenSize = gameRef.size;
    final zoomX = screenSize.x / mapPixelSize.x;
    final zoomY = screenSize.y / mapPixelSize.y;
    final zoom = zoomX < zoomY ? zoomX : zoomY;

    // gameRef.camera.viewfinder.position = mapPixelSize / 2;

    gameRef.camera.viewfinder.zoom = zoom;
    gameRef.camera.viewfinder.position = mapPixelSize / 2;
    gameRef.camera.setBounds(
      Rectangle.fromLTWH(0, 0, mapPixelSize.x, mapPixelSize.y),
    );

    if (Platform.isAndroid) gameRef.overlays.add('TouchControls');

    if (room == MainPlayerHouseRoom.room_1) {
      _spawnRoomObjects(map);
    }

    final objectGroup = map.tileMap.getLayer<ObjectGroup>('Objects');
    if (objectGroup != null) {
      for (final obj in objectGroup.objects) {
        final objType =
            obj.properties
                .firstWhere(
                  (p) => p.name == 'type',
                  orElse:
                      () => Property(
                        name: '',
                        type: PropertyType.string,
                        value: '',
                      ),
                )
                .value;

        _extractDoorSpawns(map);

        if (objType == 'door') {
          final destStr =
              obj.properties
                  .firstWhere(
                    (p) => p.name == 'destination',
                    orElse:
                        () => Property(
                          name: '',
                          type: PropertyType.string,
                          value: '',
                        ),
                  )
                  .value;

          final orientation =
              obj.properties
                      .firstWhere(
                        (p) => p.name == 'exitOrientation',
                        orElse:
                            () => Property(
                              name: '',
                              type: PropertyType.string,
                              value: '',
                            ),
                      )
                      .value
                  as String;

          final destRoom = MainPlayerHouseRoom.values.firstWhere(
            (r) => r.name == destStr,
            orElse: () => MainPlayerHouseRoom.living_room,
          );

          final position = Vector2(obj.x, obj.y);

          world.add(
            Door(
              destRoom: destRoom,
              orientation: orientation,
              onEnter:
                  () => _loadRoom(
                    destRoom,
                    previousPosition: gameRef.player.position,
                    orientation: orientation,
                    fromRoom: room.name,
                  ),
              position: position,
              size: Vector2(obj.width, obj.height),
            ),
          );
        }
      }
    }
    _addCollisions(map);

    late final Vector2 spawn;

    if (previousPosition == Vector2.zero() ||
        fromOrientation.isEmpty ||
        fromRoom.isEmpty) {
      spawn = Vector2(mapPixelSize.x - 48 - 32, mapPixelSize.y - 80 - 32);
    } else {
      spawn =
          fromRoom.isNotEmpty
              ? getSpawnPoint(
                fromRoom: fromRoom,
                orientation: fromOrientation,
                userCoordinates: gameRef.player.position,
              )
              : mapPixelSize / 2;
    }
    // fromRoom = room.name;
    fromOrientation =
        lastDirection == 'right' || lastDirection == 'left'
            ? ' horizontal'
            : 'vertical';
    final newPlayer = MainPlayer();
    newPlayer.position = spawn;
    newPlayer.lastDirection = lastDirection;
    gameRef.player = newPlayer;
    world.add(newPlayer);
  }

  void _addCollisions(TiledComponent map) {
    final objectGroup = map.tileMap.getLayer<ObjectGroup>('Objects');
    if (objectGroup == null) return;

    for (final obj in objectGroup.objects) {
      final isCollidable = obj.properties.any(
        (p) => p.name == 'collidable' && p.value == true,
      );

      if (isCollidable) {
        final pos = Vector2(obj.x, obj.y);
        final size = Vector2(obj.width, obj.height);
        gameRef.world.add(Wall(pos, size));
      }
    }
  }
}
