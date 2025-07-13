enum ItemType { keyItem, equipment, health, mana, buff }

enum EquipmentSlot { weapon, armor, accessory }

ItemType itemTypeFromString(String str) =>
    ItemType.values.firstWhere((e) => e.toString().split('.').last == str);

class Item {
  final String name;
  final ItemType type;

  const Item({required this.name, required this.type});

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString().split('.').last,
  };

  static Item fromJson(Map<String, dynamic> json) {
    return Item(name: json['name'], type: itemTypeFromString(json['type']));
  }
}

class Equipment extends Item {
  final EquipmentSlot slot;
  final int strength;
  final int defense;
  final int intelligence;

  Equipment({
    required String name,
    required this.slot,
    this.strength = 0,
    this.defense = 0,
    this.intelligence = 0,
  }) : super(name: name, type: ItemType.equipment);

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString().split('.').last,
    'slot': slot.toString().split('.').last,
    'strength': strength,
    'defense': defense,
    'intelligence': intelligence,
  };

  static Equipment fromJson(Map<String, dynamic> json) {
    return Equipment(
      name: json['name'],
      slot: EquipmentSlot.values.firstWhere(
        (e) => e.toString().split('.').last == json['slot'],
      ),
      strength: json['strength'],
      defense: json['defense'],
      intelligence: json['intelligence'],
    );
  }
}
