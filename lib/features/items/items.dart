enum ItemType { keyItem, equipment, food, medicine, currency, memorybank }

enum EquipmentSlot { weapon, clothes, footwear, accessory }

ItemType itemTypeFromString(String str) {
  return ItemType.values.firstWhere(
    (e) => e.toString().split('.').last == str,
    orElse: () => ItemType.keyItem,
  );
}

EquipmentSlot equipmentSlotFromString(String str) {
  return EquipmentSlot.values.firstWhere(
    (e) => e.toString().split('.').last == str,
    orElse: () => EquipmentSlot.weapon,
  );
}

// class Item {
//   final String name;
//   final ItemType type;
//   final double damage;
//   final int? value;

//   const Item({
//     required this.name,
//     required this.type,
//     this.value,
//     required this.damage,
//   });

//   bool get isConsumable =>
//       type == ItemType.food || type == ItemType.medicine;

//   Map<String, dynamic> toJson() => {
//     'name': name,
//     'type': type.toString().split('.').last,
//     if (value != null) 'value': value,
//   };

//   static Item fromJson(Map<String, dynamic> json) {
//     final type = itemTypeFromString(json['type']);

//     if (type == ItemType.equipment) {
//       return Equipment.fromJson(json);
//     }

//     return Item(
//       name: json['name'],
//       type: type,
//       value: json['value'],
//       damage: json['damage'],
//     );
//   }
// }

// class Equipment extends Item {
//   final EquipmentSlot slot;
//   final double damage;
//   final int defense;
//   final int intelligence;

//   Equipment({
//     required String name,
//     required this.slot,
//     this.damage = 0,
//     this.defense = 0,
//     this.intelligence = 0,
//   }) : super(name: name, type: ItemType.equipment, damage: damage);

//   @override
//   Map<String, dynamic> toJson() => {
//     'name': name,
//     'type': type.toString().split('.').last,
//     'slot': slot.toString().split('.').last,
//     'damage': damage,
//     'defense': defense,
//     'intelligence': intelligence,
//   };

//   static Equipment fromJson(Map<String, dynamic> json) {
//     return Equipment(
//       name: json['name'],
//       slot: equipmentSlotFromString(json['slot']),
//       damage: json['damage'] ?? 0,
//       defense: json['defense'] ?? 0,
//       intelligence: json['intelligence'] ?? 0,
//     );
//   }
// }
class Item {
  final String name;
  final ItemType type;
  final double damage;
  final int? value; // Effectiveness
  final int? price; // Currency value in shops

  const Item({
    required this.name,
    required this.type,
    required this.damage,
    this.value,
    this.price,
  });

  bool get isConsumable => type == ItemType.food || type == ItemType.medicine;

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString().split('.').last,
    'damage': damage,
    if (value != null) 'value': value,
    if (price != null) 'price': price,
  };

  static Item fromJson(Map<String, dynamic> json) {
    final type = itemTypeFromString(json['type']);

    if (type == ItemType.equipment) {
      return Equipment.fromJson(json);
    }

    return Item(
      name: json['name'],
      type: type,
      damage: (json['damage'] ?? 0).toDouble(),
      value: json['value'],
      price: json['price'],
    );
  }
}

class Equipment extends Item {
  final EquipmentSlot slot;
  final int defense;
  final int intelligence;

  Equipment({
    required String name,
    required this.slot,
    double damage = 0,
    this.defense = 0,
    this.intelligence = 0,
    int? price,
  }) : super(
         name: name,
         type: ItemType.equipment,
         damage: damage,
         price: price,
       );

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString().split('.').last,
    'slot': slot.toString().split('.').last,
    'damage': damage,
    'defense': defense,
    'intelligence': intelligence,
    if (price != null) 'price': price,
  };

  static Equipment fromJson(Map<String, dynamic> json) {
    return Equipment(
      name: json['name'],
      slot: equipmentSlotFromString(json['slot']),
      damage: (json['damage'] ?? 0).toDouble(),
      defense: json['defense'] ?? 0,
      intelligence: json['intelligence'] ?? 0,
      price: json['price'],
    );
  }
}
