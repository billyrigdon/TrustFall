enum MainPlayerHouseRoom { living_room, kitchen, hallway, room_1 }

extension MainPlayerHouseRoomExtension on MainPlayerHouseRoom {
  String get tmxFile {
    switch (this) {
      case MainPlayerHouseRoom.living_room:
        return 'living_room.tmx';
      case MainPlayerHouseRoom.kitchen:
        return 'kitchen.tmx';
      case MainPlayerHouseRoom.hallway:
        return 'hallway.tmx';
      case MainPlayerHouseRoom.room_1:
        return 'room_1.tmx';
    }
  }
}
