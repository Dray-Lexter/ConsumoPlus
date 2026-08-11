import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:html/parser.dart' as html_parser;

import 'electrosur_session_parser.dart';
import 'electrosur_table_reader.dart';
import 'electrosur_text_parser.dart';

class ElectrosurConsumptionParser {
  const ElectrosurConsumptionParser();

  List<ElectricityConsumptionRecord> parse(
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
        'Tarifa',
        'Consumo',
        'Total Mes',
      ]);
      return table.rows
          .map((row) {
            final period = ElectrosurTextParser.period(table.cell(row, 'Mes'));
            return ElectricityConsumptionRecord(
              providerId: providerId,
              contractNumber: contractNumber,
              billingYear: period.year,
              billingMonth: period.month,
              sourcePeriodCode: period.code,
              tariffCode: table.cell(row, 'Tarifa'),
              consumptionWh: ElectrosurTextParser.wattHours(
                table.cell(row, 'Consumo'),
              ),
              monthlyChargeCents: ElectrosurTextParser.cents(
                table.cell(row, 'Total Mes'),
              ),
              synchronizedAt: synchronizedAt,
            );
          })
          .toList(growable: false);
    } on ElectricityException {
      rethrow;
    } on Object {
      throw const ElectricitySectionStructureException('consumptions');
    }
  }
}
