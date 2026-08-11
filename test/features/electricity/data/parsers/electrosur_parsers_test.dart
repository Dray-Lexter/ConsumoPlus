import 'dart:io';

import 'package:consumo_plus/features/electricity/data/parsers/electrosur_account_status_parser.dart';
import 'package:consumo_plus/features/electricity/data/parsers/electrosur_consumption_parser.dart';
import 'package:consumo_plus/features/electricity/data/parsers/electrosur_payment_parser.dart';
import 'package:consumo_plus/features/electricity/data/parsers/electrosur_session_parser.dart';
import 'package:consumo_plus/features/electricity/data/parsers/electrosur_supply_parser.dart';
import 'package:consumo_plus/features/electricity/data/parsers/electrosur_text_parser.dart';
import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

String fixture(String name) =>
    File('test/fixtures/electrosur/$name').readAsStringSync();

void main() {
  const providerId = 'electrosur';
  const contract = '999999999';
  final synchronizedAt = DateTime.utc(2026, 8, 11, 14);

  group('ElectrosurTextParser', () {
    test('normalizes labels, periods, dates, money and energy', () {
      expect(
        ElectrosurTextParser.key('  Facturación\n del Mes: '),
        'FACTURACION DEL MES',
      );
      expect(ElectrosurTextParser.period('202607'), (
        year: 2026,
        month: 7,
        code: '202607',
      ));
      expect(ElectrosurTextParser.date('25/08/2026'), DateTime(2026, 8, 25));
      expect(ElectrosurTextParser.cents('S/. 123.4500'), 12345);
      expect(ElectrosurTextParser.wattHours('340.00 kWh'), 340000);
      expect(ElectrosurTextParser.wattHours('280,50 KWH'), 280500);
    });

    test('supports the monetary formats observed in the real DOM', () {
      expect(ElectrosurTextParser.cents('S/. 100.0000'), 10000);
      expect(ElectrosurTextParser.cents('S/. 100.5000'), 10050);
      expect(ElectrosurTextParser.cents('S/. 0'), 0);
      expect(ElectrosurTextParser.cents('S/. 0.00'), 0);
    });

    test('rejects significant fractions beyond cents', () {
      expect(
        () => ElectrosurTextParser.cents('S/. 123.4567'),
        throwsFormatException,
      );
    });
  });

  test('session parser identifies login form and authenticated content', () {
    expect(
      ElectrosurSessionParser.hasLoginForm(fixture('login_form.html')),
      isTrue,
    );
    expect(
      ElectrosurSessionParser.hasLoginForm(fixture('authenticated_home.html')),
      isFalse,
    );
  });

  test('EstadoCuenta parser reads readonly fields and semantic labels', () {
    final result = const ElectrosurAccountStatusParser().parse(
      fixture('account_status.html'),
      providerId: providerId,
      synchronizedAt: synchronizedAt,
    );

    expect(result.account.contractNumber, contract);
    expect(result.account.ownerName, 'PERSONA DE PRUEBA');
    expect(result.account.serviceAddress, 'AV. EJEMPLO 123');
    expect(result.account.tariffCode, 'BT5B');
    expect(result.status.sourcePeriodCode, '202608');
    expect(result.status.currentBillingCents, 12345);
    expect(result.status.previousDebtCents, 1000);
    expect(result.status.totalBalanceCents, 11345);
    expect(result.status.dueDate, DateTime(2026, 9, 25));
    expect(result.status.previousReadingDate, DateTime(2026, 7, 31));
  });

  test('Consumos parser follows headers instead of column positions', () {
    final records = const ElectrosurConsumptionParser().parse(
      fixture('consumptions.html'),
      providerId: providerId,
      contractNumber: contract,
      synchronizedAt: synchronizedAt,
    );

    expect(records, hasLength(3));
    expect(records.first.sourcePeriodCode, '202608');
    expect(records.first.consumptionWh, 340000);
    expect(records.first.monthlyChargeCents, 12345);
    expect(records[1].consumptionWh, 334000);
    expect(records.last.consumptionWh, 250000);
  });

  test('Pagos parser follows headers and preserves typed values', () {
    final records = const ElectrosurPaymentParser().parse(
      fixture('payments.html'),
      providerId: providerId,
      contractNumber: contract,
      synchronizedAt: synchronizedAt,
    );

    expect(records, hasLength(2));
    expect(records.first.sourcePeriodCode, '202608');
    expect(records.first.paymentDate, DateTime(2026, 8, 20));
    expect(records.first.amountCents, 12345);
    expect(records.first.paymentCenter, 'CAJA DE PRUEBA');
    expect(records.last.amountCents, 10050);
  });

  test('Suministro parser reads optional readonly details', () {
    final complete = const ElectrosurSupplyParser().parse(
      fixture('supply.html'),
    );
    final partial = const ElectrosurSupplyParser().parse(
      fixture('supply_partial.html'),
    );

    expect(complete.connectionType, 'C.1.1');
    expect(complete.feederType, 'MONOFASICO-AEREA');
    expect(complete.contractedPower, '1.20');
    expect(complete.voltageLevel, '220 V - BT');
    expect(complete.meterNumber, 'MEDIDOR123');
    expect(partial.tariffCode, 'BT5B');
    expect(partial.connectionType, isNull);
    expect(partial.feederType, isNull);
  });

  test('Suministro resolves the portal alimentador typo through name', () {
    const html = '''
      <label for="tarifa">Tarifa</label>
      <input id="tarifa" name="tarifa" readonly value="BT5B">
      <label for="alimentador">Alimentador</label>
      <div><input id="aimentador" name="alimentador" readonly value="MONOFASICO-AEREA"></div>
    ''';

    final result = const ElectrosurSupplyParser().parse(html);

    expect(result.feederType, 'MONOFASICO-AEREA');
  });

  test('authenticated section parsers report expiration, not structure', () {
    expect(
      () => const ElectrosurConsumptionParser().parse(
        fixture('login_form.html'),
        providerId: providerId,
        contractNumber: contract,
        synchronizedAt: synchronizedAt,
      ),
      throwsA(isA<ElectricitySessionExpiredException>()),
    );
  });
}
