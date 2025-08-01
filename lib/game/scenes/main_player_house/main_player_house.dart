import 'dart:io';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:game/game/scenes/main_player_house/characters/ant_battle_trigger_zone.dart';
import 'package:game/game/scenes/main_player_house/characters/main_player_house_characters.dart';
import 'package:game/game/main_player/main_player.dart';
import 'package:game/main.dart';
import 'package:game/game/scenes/main_player_house/rooms/main_player_house_room.dart';
import 'package:game/models/items.dart';
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
    // debugMode = true;
    super.onLoad();
    await _loadRoom(
      initialRoom,
      previousPosition: Vector2.zero(),
      fromRoom: '',
    );
  }

  void _extractSpawns(TiledComponent map) {
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

  void _spawnRoomObjects(TiledComponent map) {
    final objectGroup = map.tileMap.getLayer<ObjectGroup>('Objects');

    for (final obj in objectGroup!.objects) {
      final typeProp = obj.properties.firstWhere(
        (p) => p.name == 'type',
        orElse: () => Property(name: '', value: '', type: PropertyType.string),
      );

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
      final definition = MainPlayerHouseCharacters(
        gameRef: gameRef,
      ).getCharacter(id);

      if (definition == null) {
        continue;
      }

      final position = Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2);
      definition.position = position;
      definition.add(RectangleHitbox());

      gameRef.world.add(definition);
    }
  }

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

  Future<void> _loadRoom(
    MainPlayerHouseRoom room, {
    required Vector2 previousPosition,
    String? orientation,
    required String fromRoom,
  }) async {
    print('loading room');
    final lastDirection = gameRef.player.lastDirection;
    final map = await TiledComponent.load(room.tmxFile, Vector2.all(32));
    fromOrientation = orientation ?? 'horizontal';
    gameRef.mapPixelSize = mapPixelSize = map.size;
    final world = World();
    gameRef.world = world;
    gameRef.add(world);
    world.add(map);

    final screenSize = gameRef.size;
    final zoomX = screenSize.x / mapPixelSize.x;
    final zoomY = screenSize.y / mapPixelSize.y;
    final zoom = zoomX < zoomY ? zoomX : zoomY;

    gameRef.camera.viewfinder.zoom = zoom;
    gameRef.camera.viewfinder.position = mapPixelSize / 2;
    gameRef.camera.setBounds(
      Rectangle.fromLTWH(0, 0, mapPixelSize.x, mapPixelSize.y),
    );

    if (Platform.isAndroid) gameRef.overlays.add('TouchControls');

    // if (room == MainPlayerHouseRoom.room_1) {
    _spawnRoomObjects(map);

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

        _extractSpawns(map);

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

    if (room == MainPlayerHouseRoom.backyard) {
      final rng = Random();
      for (int i = 0; i < 3; i++) {
        final pos = Vector2(
          rng.nextDouble() * (mapPixelSize.x - 64),
          rng.nextDouble() * (mapPixelSize.y - 64),
        );

        world.add(AntBattleTriggerZone(pos, Vector2.all(64)));
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
}
