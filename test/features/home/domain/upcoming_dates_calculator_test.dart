import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/home/domain/upcoming_dates_calculator.dart';
import 'package:consumo_plus/features/home/domain/upcoming_dates_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('addCalendarMonths', () {
    test('crosses December into the following year', () {
      expect(
        addCalendarMonths(DateTime(2026, 12, 15), 1),
        DateTime(2027, 1, 15),
      );
    });

    test('clamps the day for leap and non-leap February', () {
      expect(
        addCalendarMonths(DateTime(2024, 1, 31), 1),
        DateTime(2024, 2, 29),
      );
      expect(
        addCalendarMonths(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28),
      );
    });

    test('uses the original day when advancing multiple months', () {
      expect(
        addCalendarMonths(DateTime(2026, 1, 31), 2),
        DateTime(2026, 3, 31),
      );
    });
  });

  group('Water schedule', () {
    test('uses the configurable estimated days 15 and 25', () {
      final schedules = const UpcomingDatesCalculator().build(
        input: const UpcomingDatesInput(
          waterConnected: true,
          electricityConnected: false,
        ),
        now: DateTime(2026, 8, 11, 18, 30),
      );

      expect(schedules, hasLength(1));
      final water = schedules.single;
      expect(water.utilityType, UtilityType.water);
      expect(water.providerName, 'EPS Tacna');
      expect(water.indicators, hasLength(2));

      final issue = water.indicators[0];
      expect(issue.label, 'Próximo recibo estimado');
      expect(issue.date, DateTime(2026, 8, 15));
      expect(issue.distanceText, 'Faltan 4 días');
      expect(issue.isEstimated, isTrue);
      expect(issue.progress, closeTo(27 / 31, 0.0001));
      expect(
        issue.semanticsLabel,
        'Agua. Próximo recibo estimado el 15 de agosto de 2026. '
        'Faltan 4 días.',
      );

      final due = water.indicators[1];
      expect(due.label, 'Próximo vencimiento estimado');
      expect(due.date, DateTime(2026, 8, 25));
      expect(due.distanceText, 'Faltan 14 días');
      expect(due.isEstimated, isTrue);
      expect(due.progress, inInclusiveRange(0, 1));
    });

    test('uses singular text one day before the event', () {
      final issue = const UpcomingDatesCalculator()
          .build(
            input: const UpcomingDatesInput(
              waterConnected: true,
              electricityConnected: false,
            ),
            now: DateTime(2026, 8, 14),
          )
          .single
          .indicators
          .first;

      expect(issue.distanceText, 'Falta 1 día');
    });

    test('describes issue and due events occurring today', () {
      final calculator = const UpcomingDatesCalculator();
      final input = const UpcomingDatesInput(
        waterConnected: true,
        electricityConnected: false,
      );

      final issue = calculator
          .build(input: input, now: DateTime(2026, 8, 15))
          .single
          .indicators[0];
      final due = calculator
          .build(input: input, now: DateTime(2026, 8, 25))
          .single
          .indicators[1];

      expect(issue.distanceText, 'Esperado hoy');
      expect(due.distanceText, 'Vence hoy');
    });

    test('advances an estimated event that already passed', () {
      final issue = const UpcomingDatesCalculator()
          .build(
            input: const UpcomingDatesInput(
              waterConnected: true,
              electricityConnected: false,
            ),
            now: DateTime(2026, 8, 16),
          )
          .single
          .indicators[0];

      expect(issue.date, DateTime(2026, 9, 15));
      expect(issue.distanceText, 'Faltan 30 días');
    });
  });

  group('Electrosur schedule', () {
    test('uses official due date and estimates the next calendar issue', () {
      final electricity = const UpcomingDatesCalculator()
          .build(
            input: UpcomingDatesInput(
              waterConnected: false,
              electricityConnected: true,
              electricityIssueDate: DateTime(2026, 8, 7, 9),
              electricityDueDate: DateTime(2026, 8, 24, 23),
            ),
            now: DateTime(2026, 8, 11, 20),
          )
          .single;

      expect(electricity.utilityType, UtilityType.electricity);
      expect(electricity.providerName, 'Electrosur');

      final issue = electricity.indicators[0];
      expect(issue.label, 'Próximo recibo estimado');
      expect(issue.date, DateTime(2026, 9, 7));
      expect(issue.distanceText, 'Faltan 27 días');
      expect(issue.isEstimated, isTrue);

      final due = electricity.indicators[1];
      expect(due.label, 'Vence tu recibo');
      expect(due.date, DateTime(2026, 8, 24));
      expect(due.distanceText, 'Faltan 13 días');
      expect(due.isEstimated, isFalse);
      expect(due.progress, closeTo(4 / 17, 0.0001));
      expect(
        due.semanticsLabel,
        'Electricidad. Vence tu recibo el 24 de agosto de 2026. '
        'Faltan 13 días.',
      );
    });

    test('describes a recently passed due date without inferring debt', () {
      final due = const UpcomingDatesCalculator()
          .build(
            input: UpcomingDatesInput(
              waterConnected: false,
              electricityConnected: true,
              electricityIssueDate: DateTime(2026, 8, 7),
              electricityDueDate: DateTime(2026, 8, 24),
            ),
            now: DateTime(2026, 8, 25),
          )
          .single
          .indicators[1];

      expect(due.distanceText, 'Venció hace 1 día');
      expect(due.progress, 1);
      expect(due.semanticsLabel, isNot(contains('deuda')));
      expect(due.semanticsLabel, isNot(contains('impago')));
    });

    test('expires the official due date at the next estimated issue', () {
      final due = const UpcomingDatesCalculator()
          .build(
            input: UpcomingDatesInput(
              waterConnected: false,
              electricityConnected: true,
              electricityIssueDate: DateTime(2026, 8, 7),
              electricityDueDate: DateTime(2026, 8, 24),
            ),
            now: DateTime(2026, 9, 7),
          )
          .single
          .indicators[1];

      expect(due.label, 'Vencimiento pendiente de actualización');
      expect(
        due.secondaryText,
        'Actualiza Electrosur para consultar la fecha del nuevo recibo.',
      );
      expect(due.date, isNull);
      expect(due.progress, isNull);
      expect(due.isEstimated, isFalse);
    });

    test('keeps advancing an old issue estimate by calendar month', () {
      final issue = const UpcomingDatesCalculator()
          .build(
            input: UpcomingDatesInput(
              waterConnected: false,
              electricityConnected: true,
              electricityIssueDate: DateTime(2026, 1, 31),
              electricityDueDate: DateTime(2026, 2, 20),
            ),
            now: DateTime(2026, 4, 1),
          )
          .single
          .indicators[0];

      expect(issue.date, DateTime(2026, 4, 30));
      expect(issue.isEstimated, isTrue);
    });

    test('uses a pending due indicator when official dates are absent', () {
      final electricity = const UpcomingDatesCalculator()
          .build(
            input: const UpcomingDatesInput(
              waterConnected: false,
              electricityConnected: true,
            ),
            now: DateTime(2026, 8, 11),
          )
          .single;

      expect(electricity.indicators, hasLength(1));
      expect(
        electricity.indicators.single.label,
        'Vencimiento pendiente de actualización',
      );
    });
  });

  test('returns only schedules for connected local accounts', () {
    const calculator = UpcomingDatesCalculator();
    final now = DateTime(2026, 8, 11);

    expect(
      calculator.build(
        input: const UpcomingDatesInput(
          waterConnected: false,
          electricityConnected: false,
        ),
        now: now,
      ),
      isEmpty,
    );
    expect(
      calculator.build(
        input: UpcomingDatesInput(
          waterConnected: true,
          electricityConnected: true,
          electricityIssueDate: DateTime(2026, 8, 7),
          electricityDueDate: DateTime(2026, 8, 24),
        ),
        now: now,
      ),
      hasLength(2),
    );
  });
}
