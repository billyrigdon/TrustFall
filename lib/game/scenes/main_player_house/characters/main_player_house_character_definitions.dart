import 'package:game/models/enemy.dart';
import 'package:game/models/attacks.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/character_stats.dart';
import 'package:game/models/party_member.dart';

//TODO: add mom, dad, bro, sis, ant, baby bird, bug, doctors1-3

abstract class MainPlayerHouseCharacterDefinitions {
  static final Map<String, BattleCharacter> characters = {
    'dude': PartyMember(
      characterId: 'dude',
      name: 'Dude',
      level: 2,
      spriteAsset: 'sprite.png',
      stats: CharacterStats(
        charClass: CharacterClass.balanced,
        maxHp: 45,
        maxMP: 45,
        strength: 1,
        speed: 1,
      ),
      attacks: [Attack(name: 'Punch', type: AttackType.physical, power: 2)],
      bank: [Attack(name: 'Lie', type: AttackType.mental, cost: 10, power: 2)],
    ),
    'ghost': Enemy(
      characterId: 'ghost',
      name: 'Ghost',
      level: 3,
      spriteAsset: 'ghost_enemy.png',
      stats: CharacterStats(
        charClass: CharacterClass.balanced,
        maxHp: 60,
        maxMP: 20,
        strength: 1,
        speed: 2,
      ),
      attacks: [Attack(name: 'Spook', type: AttackType.physical, power: 1)],
      bank: [Attack(name: 'Creep out', type: AttackType.mental, power: 3)],
    ),
    'mph_mom': PartyMember(
      characterId: 'mph_mom',
      name: 'Mom',
      level: 2,
      spriteAsset: 'mom.png',
      stats: CharacterStats(
        charClass: CharacterClass.balanced,
        maxHp: 45,
        maxMP: 45,
        strength: 1,
        speed: 1,
      ),
      attacks: [Attack(name: 'Punch', type: AttackType.physical, power: 2)],
      bank: [Attack(name: 'Lie', type: AttackType.mental, cost: 10, power: 2)],
    ),
  };

  static BattleCharacter get(String id) => characters[id]!;
}
