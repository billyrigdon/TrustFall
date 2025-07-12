import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:game/features/battle/battle_overlay.dart';
import 'package:game/features/characters/main_player.dart';
import 'package:game/features/menus/pause_menu.dart';
import 'package:game/features/menus/settings_menu.dart';
import 'package:game/features/menus/start_menu.dart';
import 'package:game/services/settings_service.dart';
import 'package:game/widgets/trust_fall_text_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // runApp(
  //   GameWidget(
  //     game: TrustFall(),
  //     overlayBuilderMap: {
  //       'TextBox': (context, game) => const TrustFallTextBox(),
  //       'PauseMenu': (context, game) => const PauseMenu(),
  //       'BattleOverlay':
  //           (context, game) => BattleOverlay(game: game as TrustFall),
  //       'StartMenu': (context, game) => StartMenu(game: game as TrustFall),
  //       'SettingsMenu':
  //           (context, game) => SettingsMenu(game: game as TrustFall),
  //     },
  //     initialActiveOverlays: const ['StartMenu'],
  //   ),
  // );
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
            'TextBox': (context, game) => const TrustFallTextBox(),
            'PauseMenu': (context, game) => const PauseMenu(),
            'BattleOverlay':
                (context, game) => BattleOverlay(game: game as TrustFall),
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
  bool isPaused = false;

  bool inBattle = false;

  late Vector2 acreSize;
  late Vector2 currentAcre;

  void startBattle() {
    inBattle = true;
    overlays.add('BattleOverlay');
  }

  void endBattle() {
    inBattle = false;
    overlays.remove('BattleOverlay');
  }

  @override
  Future<void> onLoad() async {
    final map = await TiledComponent.load('test_map.tmx', Vector2.all(32));
    player = MainPlayer()..position = Vector2(0, 0);
    player.position = Vector2(900, 300);

    world = World()..addAll([map, player]);
    // camera.follow(player);

    // final mapWidth = map.tileMap.map.width * map.tileMap.map.tileWidth;
    // final mapHeight = map.tileMap.map.height * map.tileMap.map.tileHeight;
    // camera.setBounds(
    //   Rectangle.fromLTWH(0, 0, mapWidth.toDouble(), mapHeight.toDouble()),
    // );

    // Set acre size (same size as screen for now)
    acreSize = Vector2(size.x * 0.9, size.y);
    currentAcre = _getAcreFor(player.position);

    camera.viewfinder.position = _getCameraPositionFor(currentAcre);

    final mapWidth = map.tileMap.map.width * map.tileMap.map.tileWidth;
    final mapHeight = map.tileMap.map.height * map.tileMap.map.tileHeight;
    camera.setBounds(
      Rectangle.fromLTWH(0, 0, mapWidth.toDouble(), mapHeight.toDouble()),
    );

    final tileLayer = map.tileMap.getLayer<TileLayer>('Collisions');
    if (tileLayer != null && tileLayer.tileData != null) {
      final tileData = tileLayer.tileData!;
      final tileWidth = map.tileMap.map.tileWidth.toDouble();
      final tileHeight = map.tileMap.map.tileHeight.toDouble();
      final tilesets = map.tileMap.map.tilesets;

      for (int y = 0; y < tileData.length; y++) {
        final row = tileData[y];
        for (int x = 0; x < row.length; x++) {
          final gid = row[x];
          final tileId = gid.tile;

          if (tileId == 0) continue; // skip empty

          // Find the tileset that owns this tileId
          final tileset = tilesets.firstWhere((set) {
            final firstGid = set.firstGid;
            final tileCount = set.tileCount ?? 0;
            if (firstGid == null) return false;
            return tileId >= firstGid && tileId < firstGid + tileCount;
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

  Vector2 _getAcreFor(Vector2 position) {
    final x = (position.x / acreSize.x).floorToDouble();
    final y = (position.y / acreSize.y).floorToDouble();
    return Vector2(x, y);
  }

  Vector2 _getCameraPositionFor(Vector2 acre) {
    return Vector2(
      (acre.x * acreSize.x) + acreSize.x / 2,
      (acre.y * acreSize.y) + acreSize.y / 2,
    );
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
