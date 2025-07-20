import 'package:game/models/battle_status.dart';

enum AttackType { mental, physical }

AttackType attackTypeFromString(String str) =>
    AttackType.values.firstWhere((e) => e.toString().split('.').last == str);
final class Attack {
  final String name;
  final AttackType type;
  final double power;
  final int? cost;
  final double accuracy; // 0.0 to 1.0
  final BattleStatusType? statusEffect;
  final int? statusDuration;
  final double statusDurationVariance;

  Attack({
    required this.name,
    required this.type,
    required this.power,
    this.cost,
    this.accuracy = 1.0, // Default: always hits
    this.statusEffect,
    this.statusDuration,
    this.statusDurationVariance = 0.5,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString().split('.').last,
    'power': power,
    'cost': cost,
    'accuracy': accuracy,
    'statusEffect': statusEffect?.toString().split('.').last,
    'statusDuration': statusDuration,
    'statusDurationVariance': statusDurationVariance,
  };

  factory Attack.fromJson(Map<String, dynamic> json) {
    return Attack(
      name: json['name'],
      type: attackTypeFromString(json['type']),
      power: (json['power'] as num).toDouble(),
      cost: json['cost'],
      accuracy: (json['accuracy'] ?? 1.0).toDouble(),
      statusEffect:
          json['statusEffect'] != null
              ? BattleStatusType.values.firstWhere(
                (e) => e.toString().split('.').last == json['statusEffect'],
              )
              : null,
      statusDuration: json['statusDuration'],
      statusDurationVariance:
          (json['statusDurationVariance'] ?? 0.5).toDouble(),
    );
  }
}
