import 'package:game/models/attacks.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/items.dart';

enum ActionType { attack, item, bank, run }

class BattleAction {
  final BattleCharacter actor;
  final ActionType type;
  final Attack? attack;
  final Item? item;

  BattleAction({
    required this.actor,
    required this.type,
    this.attack,
    this.item,
  });

  int get speed => actor.stats.speed.toInt();
}
