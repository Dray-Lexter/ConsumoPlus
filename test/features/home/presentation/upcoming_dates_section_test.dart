import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/home/domain/upcoming_dates_calculator.dart';
import 'package:consumo_plus/features/home/domain/upcoming_dates_models.dart';
import 'package:consumo_plus/features/home/presentation/widgets/service_schedule_card.dart';
import 'package:consumo_plus/features/home/presentation/widgets/upcoming_dates_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _subject(
  List<ServiceSchedule> schedules, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: UpcomingDatesSection(schedules: schedules),
        ),
      ),
    ),
  );
}

List<ServiceSchedule> _schedules({
  bool water = false,
  bool electricity = false,
  DateTime? now,
}) {
  return const UpcomingDatesCalculator().build(
    input: UpcomingDatesInput(
      waterConnected: water,
      electricityConnected: electricity,
      electricityIssueDate: electricity ? DateTime(2026, 8, 7) : null,
      electricityDueDate: electricity ? DateTime(2026, 8, 24) : null,
    ),
    now: now ?? DateTime(2026, 8, 11),
  );
}

void main() {
  testWidgets('renders nothing when no local account is connected', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(_schedules()));

    expect(find.text('Próximas fechas'), findsNothing);
    expect(find.byType(ServiceScheduleCard), findsNothing);
  });

  testWidgets('renders only the Water card for a local Water account', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(_schedules(water: true)));

    expect(find.text('Próximas fechas'), findsOneWidget);
    expect(find.byKey(const Key('scheduleCard-water')), findsOneWidget);
    expect(find.text('EPS Tacna'), findsOneWidget);
    expect(find.text('Electrosur'), findsNothing);
    expect(find.byType(ServiceScheduleCard), findsOneWidget);
  });

  testWidgets('renders only the Electricity card for its local account', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(_schedules(electricity: true)));

    expect(find.byKey(const Key('scheduleCard-electricity')), findsOneWidget);
    expect(find.text('Electrosur'), findsOneWidget);
    expect(find.text('EPS Tacna'), findsNothing);
    expect(find.byType(ServiceScheduleCard), findsOneWidget);
  });

  testWidgets('renders both indicators inside each connected service card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject(_schedules(water: true, electricity: true)),
    );

    expect(find.byType(ServiceScheduleCard), findsNWidgets(2));
    expect(find.text('Próximo recibo estimado'), findsNWidgets(2));
    expect(find.text('Próximo vencimiento estimado'), findsOneWidget);
    expect(find.text('Vence tu recibo'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    expect(find.textContaining('% del ciclo'), findsNothing);
  });

  testWidgets('schedule semantics describe dates without a tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_subject(_schedules(water: true)));

      final finder = find.bySemanticsLabel(
        'Agua. Próximo recibo estimado el 15 de agosto de 2026. '
        'Faltan 4 días.',
      );
      expect(finder, findsOneWidget);
      final data = tester.getSemantics(finder).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isButton, isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('stale official due date becomes a truthful update notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject(_schedules(electricity: true, now: DateTime(2026, 9, 7))),
    );

    expect(find.text('Vencimiento pendiente de actualización'), findsOneWidget);
    expect(
      find.text(
        'Actualiza Electrosur para consultar la fecha del nuevo recibo.',
      ),
      findsOneWidget,
    );
    expect(find.text('24 ago'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  for (final scale in <double>[1.3, 1.8]) {
    testWidgets('fits 320 px with ${scale}x text and remains scrollable', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _subject(
          _schedules(water: true, electricity: true),
          textScaler: TextScaler.linear(scale),
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('scheduleCard-electricity')),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      expect(find.byKey(const Key('scheduleCard-electricity')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
