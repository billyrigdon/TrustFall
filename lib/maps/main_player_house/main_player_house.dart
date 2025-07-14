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
  @override
  Future<void> onLoad() async {
    debugMode = true;
    super.onLoad();
    await _loadRoom(initialRoom, previousPosition: Vector2.zero());
  }

  Vector2 _getSpawnFromDoor(double x, double y) {
    return Vector2(x, y);
  }

  Future<void> _loadRoom(
    MainPlayerHouseRoom room, {
    required Vector2 previousPosition,
  }) async {
    final lastDirection = gameRef.player.lastDirection;
    final map = await TiledComponent.load(room.tmxFile, Vector2.all(32));
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

        final hasSpawn = obj.properties.any(
          (p) => p.name == 'spawn' && p.value == true,
        );

        if (hasSpawn) {
          doorSpawnCoordinates = Vector2(obj.x, obj.y);
        }

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

          final destRoom = MainPlayerHouseRoom.values.firstWhere(
            (r) => r.name == destStr,
            orElse: () => MainPlayerHouseRoom.livingRoom,
          );

          final position = Vector2(obj.x, obj.y);

          world.add(
            Door(
              destRoom: destRoom,
              // fromDirection: enterFrom,
              onEnter:
                  () => _loadRoom(
                    destRoom,
                    previousPosition: gameRef.player.position,
                    // fromDirection: enterFrom,
                  ),
              position: position,
              size: Vector2(obj.width, obj.height),
            ),
          );
        }
      }
    }
    _addCollisions(map);
    final spawn =
        (previousPosition == Vector2.zero())
            ? mapPixelSize / 2
            : _getSpawnFromDoor(
              gameRef.player.position.x,
              doorSpawnCoordinates!.y,
            );

    final newPlayer = MainPlayer();
    newPlayer.position = spawn;
    newPlayer.lastDirection = lastDirection;
    gameRef.player = newPlayer;
    world.add(newPlayer);
  }

  void _addCollisions(TiledComponent map) {
    final tileMap = map.tileMap.map;
    final tileLayer = map.tileMap.getLayer<TileLayer>('Collisions');
    if (tileLayer == null || tileLayer.tileData == null) return;

    final tileData = tileLayer.tileData!;
    final tilesets = tileMap.tilesets;
    final tileWidth = tileMap.tileWidth.toDouble();
    final tileHeight = tileMap.tileHeight.toDouble();

    for (int y = 0; y < tileData.length; y++) {
      final row = tileData[y];
      for (int x = 0; x < row.length; x++) {
        final gid = row[x].tile;

        if (gid == 0) continue;

        final tileset = tilesets.firstWhere(
          (set) =>
              set.firstGid != null &&
              gid >= set.firstGid! &&
              gid < set.firstGid! + (set.tileCount ?? 0),
          orElse: () => tilesets.first,
        );

        if (tileset.firstGid == null) continue;

        final localId = gid - tileset.firstGid!;
        final tile = tileset.tiles.firstWhere(
          (t) => t.localId == localId,
          orElse: () => Tile(localId: 0, properties: CustomProperties.empty),
        );

        final isCollidable = tile.properties.any(
          (p) => p.name == 'collidable' && p.value == true,
        );

        if (isCollidable) {
          final pos = Vector2(x * tileWidth, y * tileHeight);
          final size = Vector2(tileWidth, tileHeight);
          gameRef.world.add(Wall(pos, size));
        }
      }
    }
  }
}

class Door extends PositionComponent with CollisionCallbacks {
  final VoidCallback onEnter;

  Door({
    required MainPlayerHouseRoom destRoom,
    required this.onEnter,
    required Vector2 position,
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
