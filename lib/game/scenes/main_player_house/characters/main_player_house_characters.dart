import 'package:game/models/enemy.dart';
import 'package:game/game/scenes/main_player_house/characters/main_player_house_character_definitions.dart';
import 'package:game/main.dart';
import 'package:game/models/battle_character.dart';
import 'package:game/models/party_member.dart';

class MainPlayerHouseCharacters {
  TrustFall gameRef;

  MainPlayerHouseCharacters({required this.gameRef});
  getCharacters() {
    return {'ghost': getGhost(), 'dude': getDude(), 'mph_mom': getMom()};
  }

  getCharacter(String id) {
    print('getting character $id');
    return getCharacters()[id];
  }

  Enemy getGhost() {
    Enemy ghost = MainPlayerHouseCharacterDefinitions.get('ghost') as Enemy;
    ghost.onInteract = () {
      if (gameRef.dialogOpen) return;
      gameRef.dialogOpen = true;
      gameRef.showDialogue(
        worldPosition: ghost.position,
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
    PartyMember dude =
        MainPlayerHouseCharacterDefinitions.get('dude') as PartyMember;
    dude.onInteract = () {
      if (gameRef.dialogOpen) return;
      gameRef.dialogOpen = true;
      gameRef.showDialogue(
        worldPosition: dude.position,
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

  PartyMember? getMom() {
    PartyMember mom =
        MainPlayerHouseCharacterDefinitions.get('mph_mom') as PartyMember;
    mom.onInteract = () {
      if (gameRef.dialogOpen) return;
      gameRef.dialogOpen = true;
      gameRef.showDialogue(
        worldPosition: mom.position,
        [
          'Can you go check on your father?',
          'And tell your brother and sister it\'s time for dinner',
        ],
        // choices: ['Yes', 'No'],
        // onChoiceSelected: (choice) {},
      );
    };
    return mom;
  }
}
