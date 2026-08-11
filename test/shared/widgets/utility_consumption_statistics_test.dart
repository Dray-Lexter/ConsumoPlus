import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_chart.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'statistics average the latest six and describe the visible range',
    (tester) async {
      final points = List.generate(7, (index) {
        final month = index + 1;
        final value = (index + 1) * 10.0;
        return UtilityConsumptionPoint(
          year: 2026,
          month: month,
          value: value,
          periodLabel: '${_month(month)} 2026',
          displayValue: '${value.toInt()} kWh',
          semanticValue: '${value.toInt()} kilovatios hora',
        );
      }).reversed.toList();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: UtilityConsumptionStatistics(
              points: points,
              maximumAveragePeriods: 6,
              valueFormatter: (value) => '${value.toInt()} kWh',
            ),
          ),
        ),
      );

      expect(find.text('Promedio 6 meses'), findsOneWidget);
      expect(find.text('45 kWh'), findsOneWidget);
      expect(find.text('Mayor consumo'), findsOneWidget);
      expect(find.text('Jul 2026 · 70 kWh'), findsOneWidget);
      expect(find.text('Menor consumo'), findsOneWidget);
      expect(find.text('Ene 2026 · 10 kWh'), findsOneWidget);
    },
  );

  testWidgets('statistics remain absent when there are no consumption points', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UtilityConsumptionStatistics(
            points: const [],
            maximumAveragePeriods: 6,
            valueFormatter: (value) => '$value m³',
          ),
        ),
      ),
    );

    expect(find.text('Promedio 6 meses'), findsNothing);
    expect(find.byType(Card), findsNothing);
  });
}

String _month(int month) => const [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
][month - 1];
