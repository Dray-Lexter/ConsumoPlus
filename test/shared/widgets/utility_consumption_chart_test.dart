import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'summary chart keeps the latest six periods in chronological order',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_app(maxPeriods: 6, points: _thirteenPoints()));

        final chart = find.byKey(const Key('sharedChart'));
        final label = tester.getSemantics(chart).label;
        expect(label, contains('Dic 2025: 8 metros cúbicos'));
        expect(label, contains('May 2026: 13 metros cúbicos'));
        expect(label.indexOf('Dic 2025'), lessThan(label.indexOf('May 2026')));
        expect(label, isNot(contains('Nov 2025')));
        expect(label, isNot(contains('S/')));

        final painter = _painter(tester);
        expect(painter.points, hasLength(6));
        expect(painter.color, AppColors.water);
        expect(painter.minimumY, lessThan(8));
        expect(painter.maximumY, greaterThan(13));
        expect(painter.yTicks, hasLength(4));
        expect(find.byKey(const Key('chartXAxis-Dic-2025')), findsOneWidget);
        expect(find.byKey(const Key('chartYAxis-0')), findsOneWidget);
        expect(find.byKey(const Key('chartLatestPoint')), findsOneWidget);
        expect(find.text('Dic 2025 8 m³'), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'detailed chart retains twelve points but keeps X labels compact',
    (tester) async {
      await tester.pumpWidget(_app(maxPeriods: 12, points: _thirteenPoints()));

      expect(_painter(tester).points, hasLength(12));
      final visibleXLabels = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('chartXAxis-'),
      );
      expect(visibleXLabels.evaluate().length, lessThanOrEqualTo(7));
    },
  );

  testWidgets('tapping the plot reveals consumption and monetary context', (
    tester,
  ) async {
    UtilityConsumptionPoint? selected;
    await tester.pumpWidget(
      _app(
        maxPeriods: 6,
        points: _thirteenPoints(),
        onPointSelected: (point) => selected = point,
      ),
    );

    final plot = find.byKey(const Key('utilityChartPlot'));
    await tester.tapAt(tester.getCenter(plot));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(find.byKey(const Key('utilityChartTooltip')), findsOneWidget);
    expect(find.text(selected!.periodLabel), findsOneWidget);
    expect(find.text(selected!.displayValue), findsOneWidget);
    expect(find.text(selected!.contextualValue!), findsOneWidget);
  });

  testWidgets('chart remains legible at 320px with 1.3x and 1.8x text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final textScale in [1.3, 1.8]) {
      await tester.pumpWidget(
        _app(maxPeriods: 12, points: _thirteenPoints(), textScale: textScale),
      );
      expect(tester.takeException(), isNull);
      expect(_painter(tester).points, hasLength(12));
    }
  });
}

Widget _app({
  required int maxPeriods,
  required List<UtilityConsumptionPoint> points,
  ValueChanged<UtilityConsumptionPoint>? onPointSelected,
  double textScale = 1,
}) => MaterialApp(
  theme: AppTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: UtilityConsumptionChart(
          key: const Key('sharedChart'),
          utilityType: UtilityType.water,
          unit: 'm³',
          semanticTitle: 'Gráfico de consumo de Agua',
          points: points,
          maxPeriods: maxPeriods,
          onPointSelected: onPointSelected,
        ),
      ),
    ),
  ),
);

UtilityConsumptionChartPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is UtilityConsumptionChartPainter,
    ),
  );
  return paint.painter! as UtilityConsumptionChartPainter;
}

List<UtilityConsumptionPoint> _thirteenPoints() => List.generate(13, (index) {
  final period = DateTime(2025, 5 + index);
  final value = index + 1;
  return UtilityConsumptionPoint(
    year: period.year,
    month: period.month,
    value: value.toDouble(),
    periodLabel: _period(period.year, period.month),
    displayValue: '$value m³',
    semanticValue: '$value metros cúbicos',
    contextualValue: 'S/ ${value.toStringAsFixed(2)}',
  );
}).reversed.toList();

String _period(int year, int month) {
  const names = [
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
  ];
  return '${names[month - 1]} $year';
}
