import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Wall extends PositionComponent with CollisionCallbacks {
  Wall(Vector2 pos, Vector2 size)
    : super(position: pos, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }
}
