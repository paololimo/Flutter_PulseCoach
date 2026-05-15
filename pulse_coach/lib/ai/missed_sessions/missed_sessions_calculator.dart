class MissedSessionsCalculator {
  const MissedSessionsCalculator();

  int calculate(List<bool> completionFlags) =>
      completionFlags.where((completed) => !completed).length;
}
