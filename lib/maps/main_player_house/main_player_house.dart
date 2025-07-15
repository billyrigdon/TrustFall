// import 'dart:math';

import 'dart:io';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:game/features/characters/main_player.dart';
import 'package:game/main.dart';
import 'package:game/maps/main_player_house/model/main_player_house_room.dart';

class MainPlayerHouse extends Component with HasGameRef<TrustFall> {
  final MainPlayerHouseRoom initialRoom;
  MainPlayerHouse(this.initialRoom);
  late NotifyingVector2 mapPixelSize;
  Vector2? doorSpawnCoordinates;
  final Map<String, Vector2> spawnPoints = {};

  String fromOrientation = '';

  // String fromRoom = '';
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

  Vector2 _getSpawnFromDoor(Vector2 doorSpawn, Vector2 userCoordinates) {
    if (fromOrientation == 'vertical') {
      return Vector2(userCoordinates.x, doorSpawn.y);
    } else if (fromOrientation == 'horizontal') {
      return Vector2(doorSpawn.x, userCoordinates.y);
    } else
      return Vector2(0, 0);
  }

  // final Map<String, Vector2> spawnPoints = {};

  void _extractDoorSpawns(TiledComponent map) {
    final objectGroup = map.tileMap.getLayer<ObjectGroup>('Objects');
    if (objectGroup == null) return;

    for (final obj in objectGroup.objects) {
      // final hasSpawn = obj.properties.any(
      //   (p) => p.name == 'spawn' && p.value == true,
      // );
      // final fromDirection =
      //     obj.properties
      //             .firstWhere(
      //               (p) => p.name == 'fromDirection',
      //               orElse:
      //                   () => Property(
      //                     name: '',
      //                     type: PropertyType.string,
      //                     value: '',
      //                   ),
      //             )
      //             .value
      //         as String;

      // if (hasSpawn && fromDirection.isNotEmpty) {
      //   final key = '$currentRoom:$fromDirection';
      //   spawnPoints[key] = Vector2(obj.x, obj.y);
      // }

      final hasSpawn = obj.properties.any(
        (p) => p.name == 'spawn' && p.value == true,
      );

      if (hasSpawn) {
        print(obj.properties.toString());
        final fromRoom =
            obj.properties.firstWhere((p) => p.name == 'fromRoom').value
                as String;

        final fromOrientation =
            obj.properties.firstWhere((p) => p.name == 'fromOrientation').value
                as String;

        final isSpecial = obj.properties.any(
          (p) => p.name == 'special_spawn' && p.value == true,
        );

        // final key = '$fromRoom:$fromOrientation';

        final key = '$fromRoom:$fromOrientation${isSpecial ? ':special' : ''}';
        print(key);
        spawnPoints[key] = Vector2(obj.x, obj.y);
      }
    }
  }

  Vector2 getSpawnPoint({
    required String fromRoom,
    required String orientation,
    required Vector2 userCoordinates,
  }) {
    final specialKey = '$fromRoom:$orientation:special';
    final normalKey = '$fromRoom:$orientation';
    print('spawning');
    if (spawnPoints.containsKey(specialKey)) {
      print('spawning special');
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
    mapPixelSize = map.size;
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
      spawn = Vector2(
        mapPixelSize.x - 48 - 32, // near right edge
        mapPixelSize.y - 80 - 32, // near bottom edge
      );
    } else {
      // final spawnKey = '$fromRoom:$fromOrientation';
      // print(spawnKey);
      // final spawnPoint = spawnPoints[spawnKey];
      // print(spawnPoint.toString());
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

  // void _addCollisions(TiledComponent map) {
  //   final tileMap = map.tileMap.map;
  //   final tileLayer = map.tileMap.getLayer<TileLayer>('Object');
  //   if (tileLayer == null || tileLayer.tileData == null) return;

  //   final tileData = tileLayer.tileData!;
  //   final tilesets = tileMap.tilesets;
  //   final tileWidth = tileMap.tileWidth.toDouble();
  //   final tileHeight = tileMap.tileHeight.toDouble();

  //   for (int y = 0; y < tileData.length; y++) {
  //     final row = tileData[y];
  //     for (int x = 0; x < row.length; x++) {
  //       final gid = row[x].tile;

  //       if (gid == 0) continue;

  //       final tileset = tilesets.firstWhere(
  //         (set) =>
  //             set.firstGid != null &&
  //             gid >= set.firstGid! &&
  //             gid < set.firstGid! + (set.tileCount ?? 0),
  //         orElse: () => tilesets.first,
  //       );

  //       if (tileset.firstGid == null) continue;

  //       final localId = gid - tileset.firstGid!;
  //       final tile = tileset.tiles.firstWhere(
  //         (t) => t.localId == localId,
  //         orElse: () => Tile(localId: 0, properties: CustomProperties.empty),
  //       );

  //       final isCollidable = tile.properties.any(
  //         (p) => p.name == 'collidable' && p.value == true,
  //       );

  //       if (isCollidable) {
  //         final pos = Vector2(x * tileWidth, y * tileHeight);
  //         final size = Vector2(tileWidth, tileHeight);
  //         gameRef.world.add(Wall(pos, size));
  //       }
  //     }
  //   }
  // }
}

class Door extends PositionComponent with CollisionCallbacks {
  final VoidCallback onEnter;

  Door({
    required MainPlayerHouseRoom destRoom,
    required this.onEnter,
    required Vector2 position,
    required String orientation,
    required Vector2 size,
  }) {
    this.position = position;
    this.size = size;
    anchor = Anchor.topLeft;
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    if (other is MainPlayer) {
      onEnter();
    }
    super.onCollisionStart(points, other);
  }
}
