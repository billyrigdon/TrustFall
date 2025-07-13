enum AttackType { normal, fire, water, wind }

AttackType attackTypeFromString(String str) =>
    AttackType.values.firstWhere((e) => e.toString().split('.').last == str);

class Attack {
  final String name;
  final AttackType type;
  final double power;

  Attack({required this.name, required this.type, required this.power});

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString().split('.').last,
    'power': power,
  };

  factory Attack.fromJson(Map<String, dynamic> json) {
    return Attack(
      name: json['name'],
      type: attackTypeFromString(json['type']),
      power: (json['power'] as num).toDouble(),
    );
  }
}
