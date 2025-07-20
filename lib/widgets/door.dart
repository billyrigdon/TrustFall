import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:game/game/main_player/main_player.dart';
import 'package:game/game/scenes/main_player_house/rooms/main_player_house_room.dart';

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
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is MainPlayer) {
      onEnter();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
