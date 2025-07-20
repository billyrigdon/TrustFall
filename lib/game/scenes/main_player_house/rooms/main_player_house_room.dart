enum MainPlayerHouseRoom {
  living_room,
  kitchen,
  hallway,
  hallway_2,
  hallway_3,
  room_1,
  room_2,
  room_3,
  backyard,
  bathroom,
}

extension MainPlayerHouseRoomExtension on MainPlayerHouseRoom {
  String get tmxFile {
    switch (this) {
      case MainPlayerHouseRoom.living_room:
        return 'living_room.tmx';
      case MainPlayerHouseRoom.kitchen:
        return 'kitchen.tmx';
      case MainPlayerHouseRoom.hallway:
        return 'hallway.tmx';
      case MainPlayerHouseRoom.hallway_2:
        return 'hallway_2.tmx';
      case MainPlayerHouseRoom.hallway_3:
        return 'hallway_3.tmx';
      case MainPlayerHouseRoom.room_1:
        return 'room_1.tmx';
      case MainPlayerHouseRoom.room_2:
        return 'room_2.tmx';
      case MainPlayerHouseRoom.room_3:
        return 'room_3.tmx';
      case MainPlayerHouseRoom.backyard:
        return 'backyard.tmx';
      case MainPlayerHouseRoom.bathroom:
        return 'bathroom.tmx';
    }
  }
}
