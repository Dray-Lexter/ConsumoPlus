import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:html/parser.dart' as html_parser;

import 'electrosur_field_reader.dart';
import 'electrosur_session_parser.dart';
import 'electrosur_text_parser.dart';

class ParsedElectrosurAccountStatus {
  const ParsedElectrosurAccountStatus({
    required this.account,
    required this.status,
  });

  final ElectricityAccount account;
  final ElectricityAccountStatus status;
}

class ElectrosurAccountStatusParser {
  const ElectrosurAccountStatusParser();

  ParsedElectrosurAccountStatus parse(
    String html, {
    required String providerId,
    required DateTime synchronizedAt,
  }) {
    if (ElectrosurSessionParser.hasLoginForm(html)) {
      throw const ElectricitySessionExpiredException();
    }
    try {
      final fields = ElectrosurFieldReader(html_parser.parse(html));
      final contract = fields.require(const ['Suministro']);
      final period = ElectrosurTextParser.period(
        fields.require(const ['Mes Facturado']),
      );
      final account = ElectricityAccount(
        providerId: providerId,
        contractNumber: contract,
        ownerName: fields.require(const ['Nombre']),
        serviceAddress: fields.require(const ['Dirección', 'Direccion']),
        tariffCode: fields.require(const ['Tarifa']),
        synchronizedAt: synchronizedAt,
      );
      return ParsedElectrosurAccountStatus(
        account: account,
        status: ElectricityAccountStatus(
          providerId: providerId,
          contractNumber: contract,
          billingYear: period.year,
          billingMonth: period.month,
          sourcePeriodCode: period.code,
          currentBillingCents: ElectrosurTextParser.cents(
            fields.require(const [
              'Facturación del Mes',
              'Facturacion del Mes',
            ]),
          ),
          previousDebtCents: ElectrosurTextParser.cents(
            fields.require(const ['Deuda Anterior']),
          ),
          totalDebtCents: ElectrosurTextParser.cents(
            fields.require(const ['Deuda Total']),
          ),
          amountPaidCents: ElectrosurTextParser.cents(
            fields.require(const ['Monto Pagado']),
          ),
          totalBalanceCents: ElectrosurTextParser.cents(
            fields.require(const ['Saldo Total']),
          ),
          dueDate: _optionalDate(
            fields.optional(const ['Fecha de Vencimiento']),
          ),
          issueDate: _optionalDate(
            fields.optional(const ['Fecha Emisión', 'Fecha Emision']),
          ),
          readingDate: _optionalDate(fields.optional(const ['Fecha Lectura'])),
          previousReadingDate: _optionalDate(
            fields.optional(const ['Fecha Lectura Anterior']),
          ),
          synchronizedAt: synchronizedAt,
        ),
      );
    } on ElectricityException {
      rethrow;
    } on Object {
      throw const ElectricitySectionStructureException('account_status');
    }
  }

  static DateTime? _optionalDate(String? value) =>
      value == null ? null : ElectrosurTextParser.date(value);
}
