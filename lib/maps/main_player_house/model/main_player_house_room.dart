enum MainPlayerHouseRoom { livingRoom, kitchen }

extension MainPlayerHouseRoomExtension on MainPlayerHouseRoom {
  String get tmxFile {
    switch (this) {
      case MainPlayerHouseRoom.livingRoom:
        return 'living_room.tmx';
      case MainPlayerHouseRoom.kitchen:
        return 'kitchen.tmx';
    }
  }
}
