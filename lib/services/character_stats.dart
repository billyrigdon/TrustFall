enum CharacterClass { balanced, attacker, mage, healer }

class CharacterStats {
  int level;
  double xp;
  double xpToNext;
  double confidence;
  double strength;
  double defense;
  double hp;
  double speed;
  double intelligence;

  final CharacterClass charClass;
  final double levelMultiplier;

  CharacterStats({
    this.level = 1,
    this.xp = 0,
    this.xpToNext = 100,
    this.confidence = 10,
    this.strength = 10,
    this.defense = 10,
    this.hp = 50,
    this.speed = 10,
    this.intelligence = 10,
    required this.charClass,
    this.levelMultiplier = 1.0,
  });

  void gainXP(double amount) {
    xp += amount * levelMultiplier;
    while (xp >= xpToNext) {
      xp -= xpToNext;
      levelUp();
    }
  }

  void levelUp() {
    level++;
    xpToNext *= 1.2;

    final growthRates = _getGrowthRates();
    confidence += growthRates['confidence']!;
    strength += growthRates['strength']!;
    defense += growthRates['defense']!;
    hp += growthRates['hp']!;
    speed += growthRates['speed']!;
    intelligence += growthRates['intelligence']!;
  }

  Map<String, double> _getGrowthRates() {
    switch (charClass) {
      case CharacterClass.attacker:
        return {
          'confidence': 2,
          'strength': 4,
          'defense': 2,
          'hp': 5,
          'speed': 2,
          'intelligence': 1,
        };
      case CharacterClass.mage:
        return {
          'confidence': 2,
          'strength': 1,
          'defense': 1,
          'hp': 3,
          'speed': 2,
          'intelligence': 5,
        };
      case CharacterClass.healer:
        return {
          'confidence': 3,
          'strength': 1,
          'defense': 2,
          'hp': 4,
          'speed': 2,
          'intelligence': 3,
        };
      case CharacterClass.balanced:
      default:
        return {
          'confidence': 2,
          'strength': 2,
          'defense': 2,
          'hp': 4,
          'speed': 2,
          'intelligence': 2,
        };
    }
  }
}
