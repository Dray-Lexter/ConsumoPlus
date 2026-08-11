class WaterBillingSchedule {
  const WaterBillingSchedule({
    required this.expectedIssueDay,
    required this.expectedDueDay,
  }) : assert(expectedIssueDay >= 1 && expectedIssueDay <= 31),
       assert(expectedDueDay >= 1 && expectedDueDay <= 31);

  final int expectedIssueDay;
  final int expectedDueDay;
}

const epsTacnaWaterBillingSchedule = WaterBillingSchedule(
  expectedIssueDay: 15,
  expectedDueDay: 25,
);
