import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';
import 'package:html/parser.dart' as html_parser;

import 'electrosur_session_parser.dart';
import 'electrosur_table_reader.dart';
import 'electrosur_text_parser.dart';

class ElectrosurPaymentParser {
  const ElectrosurPaymentParser();

  List<ElectricityPaymentRecord> parse(
    String html, {
    required String providerId,
    required String contractNumber,
    required DateTime synchronizedAt,
  }) {
    if (ElectrosurSessionParser.hasLoginForm(html)) {
      throw const ElectricitySessionExpiredException();
    }
    try {
      final table = ElectrosurTableReader.find(html_parser.parse(html), const [
        'Mes',
        'Fecha',
        'Importe',
        'Centro de Pago',
      ]);
      return table.rows
          .map((row) {
            final period = ElectrosurTextParser.period(table.cell(row, 'Mes'));
            return ElectricityPaymentRecord(
              providerId: providerId,
              contractNumber: contractNumber,
              billingYear: period.year,
              billingMonth: period.month,
              sourcePeriodCode: period.code,
              paymentDate: ElectrosurTextParser.date(table.cell(row, 'Fecha')),
              amountCents: ElectrosurTextParser.cents(
                table.cell(row, 'Importe'),
              ),
              paymentCenter: table.cell(row, 'Centro de Pago'),
              synchronizedAt: synchronizedAt,
            );
          })
          .toList(growable: false);
    } on ElectricityException {
      rethrow;
    } on Object {
      throw const ElectricitySectionStructureException('payments');
    }
  }
}
