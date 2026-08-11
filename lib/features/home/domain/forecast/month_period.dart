class MonthPeriod implements Comparable<MonthPeriod> {
  const MonthPeriod(this.year, this.month) : assert(month >= 1 && month <= 12);

  final int year;
  final int month;

  int get ordinal => year * 12 + month - 1;

  MonthPeriod get next {
    final nextOrdinal = ordinal + 1;
    return MonthPeriod(nextOrdinal ~/ 12, nextOrdinal % 12 + 1);
  }

  int monthsUntil(MonthPeriod other) => other.ordinal - ordinal;

  bool isImmediatelyBefore(MonthPeriod other) => monthsUntil(other) == 1;

  @override
  int compareTo(MonthPeriod other) => ordinal.compareTo(other.ordinal);

  @override
  bool operator ==(Object other) =>
      other is MonthPeriod && year == other.year && month == other.month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}
