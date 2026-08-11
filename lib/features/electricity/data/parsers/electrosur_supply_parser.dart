import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:html/parser.dart' as html_parser;

import 'electrosur_field_reader.dart';
import 'electrosur_session_parser.dart';

class ElectrosurSupplyDetails {
  const ElectrosurSupplyDetails({
    this.tariffCode,
    this.connectionType,
    this.feederType,
    this.contractedPower,
    this.voltageLevel,
    this.meterNumber,
  });

  final String? tariffCode;
  final String? connectionType;
  final String? feederType;
  final String? contractedPower;
  final String? voltageLevel;
  final String? meterNumber;
}

class ElectrosurSupplyParser {
  const ElectrosurSupplyParser();

  ElectrosurSupplyDetails parse(String html) {
    if (ElectrosurSessionParser.hasLoginForm(html)) {
      throw const ElectricitySessionExpiredException();
    }
    try {
      final fields = ElectrosurFieldReader(html_parser.parse(html));
      const known = [
        'Tarifa',
        'Conexión',
        'Conexion',
        'Alimentador',
        'Potencia contratada',
        'Nivel de tensión',
        'Nivel de tension',
        'Medidor',
      ];
      if (!fields.hasAny(known)) {
        throw const ElectricitySectionStructureException('supply');
      }
      return ElectrosurSupplyDetails(
        tariffCode: fields.optional(const ['Tarifa']),
        connectionType: fields.optional(const ['Conexión', 'Conexion']),
        feederType: fields.optional(const ['Alimentador']),
        contractedPower: fields.optional(const ['Potencia contratada']),
        voltageLevel: fields.optional(const [
          'Nivel de tensión',
          'Nivel de tension',
        ]),
        meterNumber: fields.optional(const ['Medidor']),
      );
    } on ElectricityException {
      rethrow;
    } on Object {
      throw const ElectricitySectionStructureException('supply');
    }
  }
}
