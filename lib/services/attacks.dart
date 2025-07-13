enum AttackType { normal, fire, water, electric }

class Attack {
  final String name;
  final AttackType type;
  final double power;

  Attack({required this.name, required this.type, required this.power});
}
