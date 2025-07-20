enum BattleStatusType {
  stunned,
  confused,
  embarrassed,
  charmed,
  rage,
  selfDoubt,
  asleep,
}

class BattleStatus {
  final BattleStatusType type;
  int duration;

  BattleStatus({required this.type, required this.duration});
}
