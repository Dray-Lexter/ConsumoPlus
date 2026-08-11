import 'package:consumo_plus/features/water/data/parsers/portal_table_reader.dart';
import 'package:consumo_plus/features/water/data/parsers/portal_text_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/session_page_parser.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:html/parser.dart' as html_parser;

class PaymentParser {
  const PaymentParser();

  List<PaymentRecord> parse(
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
      final date = table.requireIndex(
        (header) => header.contains('FECHA') && header.contains('PAGO'),
      );
      final center = table.requireIndex(
        (header) => header.contains('CENTRO') && header.contains('PAGO'),
      );
      final year = table.requireIndex((header) => header == 'ANO');
      final month = table.requireIndex((header) => header == 'MES');
      final documentType = table.requireIndex(
        (header) => header.contains('TIPO') && header.contains('CP'),
      );
      final receipt = table.requireIndex(
        (header) => header.contains('COMPROBANTE'),
      );
      final amount = table.requireIndex((header) => header == 'MONTO');
      final detail = table.requireIndex((header) => header == 'DETALLE');

      return table.rows
          .map((row) {
            return PaymentRecord(
              providerId: providerId,
              customerCode: customerCode,
              paymentDate: PortalTextParser.date(table.cell(row, date)),
              paymentCenter: table.cell(row, center),
              paymentYear: PortalTextParser.integer(table.cell(row, year)),
              paymentMonth: PortalTextParser.month(table.cell(row, month)),
              documentType: table.cell(row, documentType),
              receiptNumber: table.cell(row, receipt),
              amountCents: PortalTextParser.cents(table.cell(row, amount)),
              detail: table.cell(row, detail),
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
