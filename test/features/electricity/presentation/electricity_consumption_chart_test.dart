import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_consumption_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('consumption chart orders and limits accessible kWh periods', (
    tester,
  ) async {
    final synchronizedAt = DateTime.utc(2026, 8, 11);
    final records = List.generate(13, (index) {
      final period = DateTime(2025, 5 + index);
      return ElectricityConsumptionRecord(
        providerId: 'electrosur',
        contractNumber: '999999999',
        billingYear: period.year,
        billingMonth: period.month,
        sourcePeriodCode:
            '${period.year}${period.month.toString().padLeft(2, '0')}',
        tariffCode: 'BT5B',
        consumptionWh: (index + 1) * 1000,
        monthlyChargeCents: 10000,
        synchronizedAt: synchronizedAt,
      );
    }).reversed.toList();
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ElectricityConsumptionScreen(records: records),
      ),
    );
    await tester.pumpAndSettle();

    final chart = find.byKey(const Key('electricityConsumptionChart'));
    expect(chart, findsOneWidget);
    final label = tester.getSemantics(chart).label;
    expect(label, contains('Jun 2025: 2 kWh'));
    expect(label, contains('May 2026: 13 kWh'));
    expect(label.indexOf('Jun 2025'), lessThan(label.indexOf('May 2026')));
    expect(label, isNot(contains('May 2025')));
    expect(label, isNot(contains('S/')));
    semantics.dispose();
  });
}
