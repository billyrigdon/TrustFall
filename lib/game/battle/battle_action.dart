import 'package:game/models/attacks.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/items.dart';

enum ActionType { attack, bank, item, throwItem, run }

class BattleAction {
  final BattleCharacter actor;
  final ActionType type;
  final Attack? attack;
  final Item? item;
  final BattleCharacter? target;

  BattleAction({
    required this.actor,
    required this.type,
    this.attack,
    this.item,
    this.target,
  });

  int get speed => actor.stats.speed.toInt();
}
