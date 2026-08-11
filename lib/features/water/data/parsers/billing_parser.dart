import 'package:consumo_plus/features/water/data/parsers/portal_table_reader.dart';
import 'package:consumo_plus/features/water/data/parsers/portal_text_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/session_page_parser.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:html/parser.dart' as html_parser;

class BillingParser {
  const BillingParser();

  List<BillingRecord> parse(
    String source, {
    required String providerId,
    required String customerCode,
    required DateTime synchronizedAt,
  }) {
    if (SessionPageParser.hasLoginForm(source)) {
      throw const SessionExpiredException();
    }

    try {
      final table = PortalTableReader(html_parser.parse(source));
      final period = table.requireIndex((header) => header == 'PERIODO');
      final receipt = table.requireIndex((header) => header.contains('RECIBO'));
      final consumption = table.requireIndex((header) => header == 'CONSUMO');
      final average = table.requireIndex(
        (header) => header.contains('LECT') && header.contains('PROM'),
      );
      final monthly = table.requireIndex((header) => header == 'TOTAL MES');
      final overdue = table.requireIndex(
        (header) =>
            header.contains('MES') &&
            (header.contains('ATRAZ') || header.contains('ATRAS')),
      );
      final debt = table.requireIndex((header) => header == 'DEUDA');
      final total = table.requireIndex((header) => header == 'TOTAL');

      return table.rows
          .map((row) {
            final periodLabel = table.cell(row, period);
            return BillingRecord(
              providerId: providerId,
              customerCode: customerCode,
              billingYear: PortalTextParser.year(periodLabel),
              billingMonth: PortalTextParser.month(periodLabel),
              sourcePeriodLabel: periodLabel,
              receiptNumber: table.cell(row, receipt),
              consumptionCubicMeters: PortalTextParser.decimal(
                table.cell(row, consumption),
              ),
              averageReading: PortalTextParser.decimal(
                table.cell(row, average),
              ),
              monthlyChargeCents: PortalTextParser.cents(
                table.cell(row, monthly),
              ),
              overdueMonths: PortalTextParser.integer(table.cell(row, overdue)),
              outstandingDebtCents: PortalTextParser.cents(
                table.cell(row, debt),
              ),
              totalAmountCents: PortalTextParser.cents(table.cell(row, total)),
              synchronizedAt: synchronizedAt,
            );
          })
          .toList(growable: false);
    } on WaterException {
      rethrow;
    } on Object {
      throw const UnexpectedPortalStructureException();
    }
  }
}
