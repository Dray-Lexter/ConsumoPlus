import 'dart:io';

import 'package:consumo_plus/features/water/data/parsers/account_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/billing_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/payment_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/portal_text_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/session_page_parser.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:flutter_test/flutter_test.dart';

String fixture(String name) {
  return File('test/fixtures/eps_tacna/$name').readAsStringSync();
}

void main() {
  const providerId = 'eps-tacna';
  const customerCode = 'CLIENTE-DE-PRUEBA';
  final synchronizedAt = DateTime.utc(2026, 8, 4, 12);

  group('PortalTextParser', () {
    test('normalizes Spanish months, dates and decimal formats', () {
      expect(PortalTextParser.month('FEBRERO'), 2);
      expect(PortalTextParser.month('setiembre'), 9);
      expect(PortalTextParser.month('DICIÉMBRE'), 12);
      expect(PortalTextParser.date('15/07/2026'), DateTime(2026, 7, 15));
      expect(PortalTextParser.date('2026-06-10'), DateTime(2026, 6, 10));
      expect(() => PortalTextParser.date('31/02/2026'), throwsFormatException);
      expect(PortalTextParser.decimal('12,5 m³'), 12.5);
    });

    test('converts Peruvian money to integer cents', () {
      expect(PortalTextParser.cents('S/ 24.50'), 2450);
      expect(PortalTextParser.cents('S/ 18,40'), 1840);
      expect(PortalTextParser.cents('S/ 1,234.56'), 123456);
      expect(PortalTextParser.cents('S/ 1.234,56'), 123456);
    });
  });

  test('session parser distinguishes authenticated shell and login form', () {
    expect(
      SessionPageParser.isAuthenticated(fixture('authenticated_shell.html')),
      isTrue,
    );
    expect(
      SessionPageParser.hasLoginForm(fixture('authenticated_shell.html')),
      isFalse,
    );
    expect(SessionPageParser.hasLoginForm(fixture('login_form.html')), isTrue);
  });

  test('account parser reads the identity from the authenticated shell', () {
    final account = const AccountParser().parse(
      fixture('authenticated_shell.html'),
      providerId: providerId,
      customerCode: customerCode,
      synchronizedAt: synchronizedAt,
    );

    expect(account.ownerName, 'PERSONA DE PRUEBA');
    expect(account.customerCode, customerCode);
  });

  test('account parser extracts seven fields from the billing information', () {
    final shellAccount = WaterAccount(
      providerId: providerId,
      customerCode: 'CODIGO-ANTERIOR',
      ownerName: 'TITULAR ANTERIOR',
      synchronizedAt: synchronizedAt,
    );

    final account = const AccountParser().withSupplyDetails(
      fixture('billing_history.html'),
      account: shellAccount,
    );

    expect(account.customerCode, '123456');
    expect(account.ownerName, 'PERSONA DE PRUEBA');
    expect(account.serviceAddress, 'AV. EJEMPLO 123');
    expect(account.serviceStatus, 'OPERATIVO');
    expect(account.tariffName, 'DOMESTICA');
    expect(account.meterNumber, 'MEDIDOR123');
    expect(account.connectionType, 'AGUA');
  });

  test('account parser tolerates label variants, spaces and line breaks', () {
    final account = const AccountParser().withSupplyDetails(
      fixture('billing_history.html'),
      account: WaterAccount(
        providerId: providerId,
        customerCode: customerCode,
        ownerName: 'PERSONA ANTERIOR',
        synchronizedAt: synchronizedAt,
      ),
    );

    expect(account.serviceAddress, 'AV. EJEMPLO 123');
    expect(account.serviceStatus, 'OPERATIVO');
    expect(account.meterNumber, 'MEDIDOR123');
    expect(account.connectionType, 'AGUA');
  });

  test('an absent optional supply field does not reject billing data', () {
    final account = const AccountParser().withSupplyDetails(
      fixture('billing_history_partial.html'),
      account: WaterAccount(
        providerId: providerId,
        customerCode: customerCode,
        ownerName: 'PERSONA ANTERIOR',
        synchronizedAt: synchronizedAt,
      ),
    );

    expect(account.customerCode, '123456');
    expect(account.ownerName, 'PERSONA DE PRUEBA');
    expect(account.meterNumber, 'MEDIDOR123');
    expect(account.connectionType, isNull);
  });

  test('a completely unrelated page is a structure error, not credentials', () {
    final operation = () => const AccountParser().withSupplyDetails(
      fixture('unrelated_page.html'),
      account: WaterAccount(
        providerId: providerId,
        customerCode: customerCode,
        ownerName: 'PERSONA DE PRUEBA',
        synchronizedAt: synchronizedAt,
      ),
    );

    expect(
      operation,
      throwsA(
        allOf(
          isA<UnexpectedPortalStructureException>(),
          isNot(isA<InvalidCredentialsException>()),
        ),
      ),
    );
  });

  test('billing parser uses headers and returns every HTML row', () {
    final records = const BillingParser().parse(
      fixture('billing_history.html'),
      providerId: providerId,
      customerCode: customerCode,
      synchronizedAt: synchronizedAt,
    );

    expect(records, hasLength(3));
    expect(records.first.billingMonth, 7);
    expect(records.first.billingYear, 2026);
    expect(records.first.monthlyChargeCents, 2450);
    expect(records.first.outstandingDebtCents, 1020);
    expect(records.first.totalAmountCents, 3470);
    expect(records.last.billingMonth, 5);
    expect(records.last.monthlyChargeCents, 123456);
  });

  test('payment parser uses headers and typed values', () {
    final records = const PaymentParser().parse(
      fixture('payment_history.html'),
      providerId: providerId,
      customerCode: customerCode,
      synchronizedAt: synchronizedAt,
    );

    expect(records, hasLength(2));
    expect(records.first.paymentDate, DateTime(2026, 7, 15));
    expect(records.first.paymentMonth, 7);
    expect(records.first.amountCents, 3470);
    expect(records.last.paymentMonth, 6);
  });

  test('authenticated parsers reject an expired session', () {
    expect(
      () => const BillingParser().parse(
        fixture('login_form.html'),
        providerId: providerId,
        customerCode: customerCode,
        synchronizedAt: synchronizedAt,
      ),
      throwsA(isA<SessionExpiredException>()),
    );
  });

  test('billing parser rejects missing mandatory headers', () {
    expect(
      () => const BillingParser().parse(
        fixture('missing_headers.html'),
        providerId: providerId,
        customerCode: customerCode,
        synchronizedAt: synchronizedAt,
      ),
      throwsA(isA<UnexpectedPortalStructureException>()),
    );
  });
}
