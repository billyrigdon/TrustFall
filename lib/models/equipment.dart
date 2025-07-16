import 'package:game/models/items.dart';

enum EquipmentSlot { weapon, clothes, footwear, accessory }

EquipmentSlot equipmentSlotFromString(String str) {
  return EquipmentSlot.values.firstWhere(
    (e) => e.toString().split('.').last == str,
    orElse: () => EquipmentSlot.weapon,
  );
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
