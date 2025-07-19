import 'package:flutter/material.dart';
import 'package:game/models/equipment.dart';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
// import 'package:game/models/item.dart';
import 'package:game/main.dart';

enum ItemType { keyItem, equipment, food, medicine, currency, memorybank }

ItemType itemTypeFromString(String str) {
  return ItemType.values.firstWhere(
    (e) => e.toString().split('.').last == str,
    orElse: () => ItemType.keyItem,
  );
}

// class Item {
//   final String name;
//   final ItemType type;
//   final double damage;
//   final int? value; // Effectiveness
//   final int? price; // Currency value in shops

//   const Item({
//     required this.name,
//     required this.type,
//     required this.damage,
//     this.value,
//     this.price,
//   });

//   bool get isConsumable => type == ItemType.food || type == ItemType.medicine;

//   Map<String, dynamic> toJson() => {
//     'name': name,
//     'type': type.toString().split('.').last,
//     'damage': damage,
//     if (value != null) 'value': value,
//     if (price != null) 'price': price,
//   };

//   static Item fromJson(Map<String, dynamic> json) {
//     final type = itemTypeFromString(json['type']);

//     if (type == ItemType.equipment) {
//       return Equipment.fromJson(json);
//     }

//     return Item(
//       name: json['name'],
//       type: type,
//       damage: (json['damage'] ?? 0).toDouble(),
//       value: json['value'],
//       price: json['price'],
//     );
//   }
// }

class Item {
  final String name;
  final ItemType type;
  final double damage;
  final int? value;
  final int? price;
  final String spriteAsset; // NEW

  const Item({
    required this.name,
    required this.type,
    required this.damage,
    this.value,
    this.price,
    required this.spriteAsset,
  });

  bool get isConsumable => type == ItemType.food || type == ItemType.medicine;

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString().split('.').last,
    'damage': damage,
    if (value != null) 'value': value,
    if (price != null) 'price': price,
    if (spriteAsset != null) 'spriteAsset': spriteAsset,
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
      spriteAsset: json['spriteAsset'],
    );
  }
}

// suming this has gameRef

class ItemComponent extends SpriteComponent
    with CollisionCallbacks, HasGameRef<TrustFall> {
  final Item item;
  VoidCallback? onPickedUp;

  ItemComponent({required this.item, Vector2? position, Vector2? size})
    : super(position: position, size: size ?? Vector2.all(16));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    print('loaded item');
    sprite = await gameRef.loadSprite(item.spriteAsset);
    add(RectangleHitbox());
  }

  void tryPickUp(Vector2 playerPosition, Rect playerRect) {
    if (playerRect.inflate(10).overlaps(toRect())) {
      gameRef.player.addItem(item);
      gameRef.showDialogue(
        ["You picked up ${item.name}!"],
        choices: [],
        onChoiceSelected: (_) {},
      );
      removeFromParent(); // remove from the world
      onPickedUp?.call();
    }
  }
}
