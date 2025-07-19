enum AttackType { mental, physical }

AttackType attackTypeFromString(String str) =>
    AttackType.values.firstWhere((e) => e.toString().split('.').last == str);

class Attack {
  final String name;
  final AttackType type;
  final double power;
  final int? cost;

  Attack({
    required this.name,
    required this.type,
    required this.power,
    this.cost,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString().split('.').last,
    'power': power,
    'cost': cost,
  };

  factory Attack.fromJson(Map<String, dynamic> json) {
    return Attack(
      name: json['name'],
      type: attackTypeFromString(json['type']),
      power: (json['power'] as num).toDouble(),
      cost: json['cost'] ?? 0,
    );
  }
}
