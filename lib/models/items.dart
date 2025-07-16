import 'package:game/models/equipment.dart';

enum ItemType { keyItem, equipment, food, medicine, currency, memorybank }

ItemType itemTypeFromString(String str) {
  return ItemType.values.firstWhere(
    (e) => e.toString().split('.').last == str,
    orElse: () => ItemType.keyItem,
  );
}


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

