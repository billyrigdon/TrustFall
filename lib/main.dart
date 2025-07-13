import 'dart:io' show Platform;

import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:game/features/battle/battle_overlay.dart';
import 'package:game/features/characters/battle_character.dart';
import 'package:game/features/characters/enemies/test_enemy.dart';
import 'package:game/features/characters/main_player.dart';
import 'package:game/features/characters/party/PartyMember.dart';
import 'package:game/features/menus/pause_menu.dart';
import 'package:game/features/menus/settings_menu.dart';
import 'package:game/features/menus/start_menu.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/touch_overlay.dart';
import 'package:game/widgets/trust_fall_text_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().load(); // <- load settings early
  // var prefs = await SharedPreferences.getInstance();
  // await prefs.clear();
  runApp(
    MaterialApp(
      title: 'TrustFall',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget(
          game: TrustFall(),
          overlayBuilderMap: {
            if (Platform.isAndroid)
              'TouchControls':
                  (context, game) => TouchControls(
                    onInput: (label, isPressed) {
                      final player = (game as TrustFall).player;
                      player.handleTouchInput(label, isPressed);
                    },
                  ),
            'TextBox': (context, game) => const TrustFallTextBox(),
            'PauseMenu':
                (context, game) =>
                    PauseMenu(player: (game as TrustFall).player),
            'BattleOverlay': (context, game) {
              final trustFall = game as TrustFall;
              return BattleOverlay(
                game: trustFall,
                party: trustFall.currentParty,
                enemy: trustFall.currentEnemy,
              );
            },
            'StartMenu': (context, game) => StartMenu(game: game as TrustFall),
            'SettingsMenu':
                (context, game) => SettingsMenu(game: game as TrustFall),
          },
          initialActiveOverlays: const ['StartMenu'],
        ),
      ),
    ),
  );
}

class TrustFall extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late final MainPlayer player;
  List<BattleCharacter> currentParty = [];
  late Enemy currentEnemy;
  bool isPaused = false;

  bool inBattle = false;

  late Vector2 acreSize;
  late Vector2 currentAcre;

  void startBattle(List<BattleCharacter> party, Enemy enemy) {
    currentParty = party;

    currentEnemy = enemy;

    inBattle = true;
    overlays.add('BattleOverlay');
  }

  void endBattle() {
    inBattle = false;
    overlays.remove('BattleOverlay');
  }

  @override
  Future<void> onLoad() async {
    final map = await TiledComponent.load('living_room.tmx', Vector2.all(32));
    final tileMap = map.tileMap.map;

    final tileWidth = tileMap.tileWidth.toDouble();
    final tileHeight = tileMap.tileHeight.toDouble();
    final mapWidth = tileMap.width * tileMap.tileWidth;
    final mapHeight = tileMap.height * tileMap.tileHeight;

    final tileMapWidth = mapWidth.toDouble();
    final tileMapHeight = mapHeight.toDouble();

    // Add the map to the world first
    world = World()..add(map);
    add(world);

    // Calculate zoom so the map fills the screen
    // final zoomX = size.x / tileMapWidth;
    // final zoomY = size.y / tileMapHeight;
    // final zoom = zoomX < zoomY ? zoomX : zoomY;

    // camera.viewfinder.zoom = zoom;
    camera.viewport = FixedResolutionViewport(resolution: Vector2(640, 384));
    // Calculate visible world area based on zoom (this becomes your acre size)
    final visibleWidth = size.x;
    final visibleHeight = size.y;
    acreSize = Vector2(visibleWidth, visibleHeight);

    // Initialize player in center of map
    player =
        MainPlayer()..position = Vector2(tileMapWidth / 2, tileMapHeight / 2);
    if (Platform.isAndroid) {
      overlays.add('TouchControls');
    }

    world.add(player);

    // Set camera bounds to prevent black edges
    camera.setBounds(Rectangle.fromLTWH(0, 0, tileMapWidth, tileMapHeight));

    // Position camera on player's acre, clamped inside bounds
    currentAcre = _getAcreFor(player.position);
    final target = _getCameraPositionFor(currentAcre);

    final clampedX = _clampCameraAxis(target.x, visibleWidth, tileMapWidth);
    final clampedY = _clampCameraAxis(target.y, visibleHeight, tileMapHeight);

    camera.viewfinder.position = Vector2(clampedX, clampedY);

    // Load collision walls from Collisions layer
    final tileLayer = map.tileMap.getLayer<TileLayer>('Collisions');
    if (tileLayer != null && tileLayer.tileData != null) {
      final tileData = tileLayer.tileData!;
      final tilesets = tileMap.tilesets;

      for (int y = 0; y < tileData.length; y++) {
        final row = tileData[y];
        for (int x = 0; x < row.length; x++) {
          final gid = row[x];
          final tileId = gid.tile;

          if (tileId == 0) continue;

          final tileset = tilesets.firstWhere((set) {
            final firstGid = set.firstGid;
            final tileCount = set.tileCount ?? 0;
            return firstGid != null &&
                tileId >= firstGid &&
                tileId < firstGid + tileCount;
          });

          if (tileset == null || tileset.firstGid == null) continue;

          final localId = tileId - tileset.firstGid!;
          final tile = tileset.tiles.firstWhere((t) => t.localId == localId);

          final isCollidable =
              tile?.properties.any(
                (p) => p.name == 'collidable' && p.value == true,
              ) ??
              false;

          if (isCollidable) {
            final pos = Vector2(x * tileWidth, y * tileHeight);
            final size = Vector2(tileWidth, tileHeight);
            world.add(Wall(pos, size));
          }
        }
      }
    }
  }

  double _clampCameraAxis(double target, double visible, double maxMap) {
    if (visible >= maxMap) {
      return maxMap / 2; // center the camera on small maps
    }
    final min = visible / 2;
    final max = maxMap - visible / 2;
    return target.clamp(min, max);
  }

  double _calculateZoomToFillMap(mapWidth, mapHeight) {
    // final mapWidth = world.size.x;
    // final mapHeight = world.size.y;

    final zoomX = size.x / mapWidth;
    final zoomY = size.y / mapHeight;

    return zoomX < zoomY ? zoomX : zoomY; // Fit screen inside map
  }

  @override
  void update(double dt) {
    if (!isPaused) {
      super.update(dt);

      final newAcre = _getAcreFor(player.position);
      if (newAcre != currentAcre) {
        currentAcre = newAcre;
        camera.moveTo(_getCameraPositionFor(currentAcre));
      }
    }
  }

  // Vector2 _getAcreFor(Vector2 position) {
  //   final x = (position.x / acreSize.x).floorToDouble();
  //   final y = (position.y / acreSize.y).floorToDouble();
  //   return Vector2(x, y);
  // }

  // Vector2 _getCameraPositionFor(Vector2 acre) {
  //   return Vector2(
  //     (acre.x * acreSize.x) + acreSize.x / 2,
  //     (acre.y * acreSize.y) + acreSize.y / 2,
  //   );
  // }

  /// Gets the top-left acre the player is currently in
  Vector2 _getAcreFor(Vector2 position) {
    final x = (position.x / acreSize.x).floorToDouble();
    final y = (position.y / acreSize.y).floorToDouble();
    return Vector2(x, y);
  }

  /// Returns the camera position that centers on the entire room (acre),
  /// regardless of the player's position in that room.
  Vector2 _getCameraPositionFor(Vector2 acre) {
    // Instead of using the center of the acre, return the center of the room's full dimensions
    final topLeft = Vector2(acre.x * acreSize.x, acre.y * acreSize.y);
    final center = topLeft + acreSize / 2;
    return center;
  }

  void togglePause() {
    isPaused = !isPaused;
    if (isPaused) {
      overlays.add('PauseMenu');
    } else {
      overlays.remove('PauseMenu');
    }
  }

  void showTextBox() {
    overlays.add('TextBox');
    Future.delayed(const Duration(seconds: 2), () {
      overlays.remove('TextBox');
    });
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  Wall(Vector2 position, Vector2 size) {
    // debugMode = true;
    this.position = position;
    this.size = size;
    add(
      RectangleHitbox()..collisionType = CollisionType.passive, // important!
    );
  }
}
