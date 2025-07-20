class CanActResult {
  final bool canAct;
  final bool forceRandomTarget;
  final bool forceAttack;
  final bool blockSelfSupport;

  CanActResult({
    this.canAct = true,
    this.forceRandomTarget = false,
    this.forceAttack = false,
    this.blockSelfSupport = false,
  });
}
