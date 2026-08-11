import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_consumption_screen.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_chart.dart';
import 'package:consumo_plus/shared/widgets/history_record_card.dart';
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
    final paint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is UtilityConsumptionChartPainter,
      ),
    );
    expect(
      (paint.painter! as UtilityConsumptionChartPainter).points,
      hasLength(12),
    );
    expect(find.text('Promedio 6 meses'), findsOneWidget);
    expect(find.text('10.5 kWh'), findsOneWidget);
    expect(find.text('Jun 2025 2 kWh'), findsNothing);
    semantics.dispose();
  });

  testWidgets('consumption cards show the newest period first', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final synchronizedAt = DateTime.utc(2026, 8, 11);
    final records = [
      ElectricityConsumptionRecord(
        providerId: 'electrosur',
        contractNumber: '999999999',
        billingYear: 2026,
        billingMonth: 6,
        sourcePeriodCode: '202606',
        tariffCode: 'BT5B',
        consumptionWh: 120000,
        monthlyChargeCents: 10000,
        synchronizedAt: synchronizedAt,
      ),
      ElectricityConsumptionRecord(
        providerId: 'electrosur',
        contractNumber: '999999999',
        billingYear: 2026,
        billingMonth: 7,
        sourcePeriodCode: '202607',
        tariffCode: 'BT5B',
        consumptionWh: 130000,
        monthlyChargeCents: 11000,
        synchronizedAt: synchronizedAt,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ElectricityConsumptionScreen(records: records),
      ),
    );
    await tester.pumpAndSettle();

    final newest = find.byKey(const Key('electricityConsumption-202607'));
    final oldest = find.byKey(const Key('electricityConsumption-202606'));
    expect(find.byType(HistoryRecordCard), findsNWidgets(2));
    expect(newest, findsOneWidget);
    expect(oldest, findsOneWidget);
    expect(
      tester.getTopLeft(newest).dy,
      lessThan(tester.getTopLeft(oldest).dy),
    );
  });
}
