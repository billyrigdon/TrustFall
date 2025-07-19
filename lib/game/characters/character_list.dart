import 'package:flame/components.dart';
import 'package:game/game/characters/enemies/enemy.dart';
import 'package:game/main.dart';
import 'package:game/models/attacks.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/character_stats.dart';
import 'package:game/models/party_member.dart';

abstract class CharacterDefinitions {
  static final Map<String, BattleCharacter> characters = {
    'dude': PartyMember(
      characterId: 'dude',
      name: 'Dude',
      level: 2,
      spriteAsset: 'sprite.png',
      stats: CharacterStats(
        charClass: CharacterClass.balanced,
        maxHp: 45,
        strength: 1,
      ),
      attacks: [Attack(name: 'Punch', type: AttackType.physical, power: 2)],
    ),
    'ghost': Enemy(
      characterId: 'ghost',
      name: 'Ghost',
      level: 3,
      spriteAsset: 'ghost_enemy.png',
      stats: CharacterStats(
        charClass: CharacterClass.balanced,
        maxHp: 60,
        strength: 1,
      ),
      attacks: [Attack(name: 'Spook', type: AttackType.physical, power: 1)],
    ),
  };

  static BattleCharacter get(String id) => characters[id]!;
}

class MainPlayerHouseCharacterDefinitions {
  TrustFall gameRef;

  MainPlayerHouseCharacterDefinitions({required this.gameRef});
  getCharacters() {
    return {'ghost': getGhost(), 'dude': getDude()};
  }

  Enemy getGhost() {
    Enemy ghost = CharacterDefinitions.get('ghost') as Enemy;
    ghost.onInteract = () {
      if (gameRef.dialogOpen) return;
      gameRef.dialogOpen = true;
      gameRef.showDialogue(
        ['Boo'],
        onComplete: () {
          gameRef.dialogOpen = false;
          gameRef.startBattle([
            gameRef.player as BattleCharacter,
            ...gameRef.player.currentParty.where(
              (c) => c.name != gameRef.player.name,
            ),
          ], ghost);
        },
      );
    };
    return ghost;
  }

  PartyMember? getDude() {
    PartyMember dude = CharacterDefinitions.get('dude') as PartyMember;
    dude.onInteract = () {
      if (gameRef.dialogOpen) return;
      gameRef.dialogOpen = true;
      gameRef.showDialogue(
        ['Hi there!', 'can i join your party??'],
        choices: ['Yes', 'No'],
        onChoiceSelected: (choice) {
          gameRef.dialogOpen = false;
          if (choice == 'Yes') {
            gameRef.player.addToParty(dude);
            gameRef.world.remove(dude);
          }
        },
      );
    };
    bool isInParty = gameRef.player.currentParty.any(
      (member) => member.characterId == 'dude',
    );
    if (!isInParty) return dude;
    return null;
  }
}
