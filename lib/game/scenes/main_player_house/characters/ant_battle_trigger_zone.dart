import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:game/game/main_player/main_player.dart';
import 'package:game/game/scenes/main_player_house/characters/main_player_house_characters.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/main.dart';

class AntBattleTriggerZone extends PositionComponent
    with CollisionCallbacks, HasGameRef<TrustFall> {
  bool triggered = false;

  AntBattleTriggerZone(Vector2 position, Vector2 size) {
    this.position = position;
    this.size = size;
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    priority = -1;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (triggered || other is! MainPlayer) return;

    triggered = true;

    final ant = MainPlayerHouseCharacters(
      gameRef: gameRef,
    ).getCharacter('mph_ant');
    if (ant == null) return;

    gameRef.startBattle([
      gameRef.player as BattleCharacter,
      ...gameRef.player.currentParty.where(
        (c) => c.name != gameRef.player.name,
      ),
    ], ant);

    removeFromParent();
  }
}
