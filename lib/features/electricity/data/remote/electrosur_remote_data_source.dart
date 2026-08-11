import 'package:consumo_plus/features/electricity/data/parsers/electrosur_account_status_parser.dart';
import 'package:consumo_plus/features/electricity/data/parsers/electrosur_consumption_parser.dart';
import 'package:consumo_plus/features/electricity/data/parsers/electrosur_payment_parser.dart';
import 'package:consumo_plus/features/electricity/data/parsers/electrosur_supply_parser.dart';
import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';

import 'electrosur_http_client.dart';

typedef ElectrosurHttpClientFactory = ElectrosurHttpClient Function();

abstract interface class ElectrosurRemoteSource {
  Future<ElectrosurRemoteData> synchronize({
    required String contractNumber,
    required String password,
    required DateTime synchronizedAt,
  });
}

class ElectrosurRemoteDataSource implements ElectrosurRemoteSource {
  const ElectrosurRemoteDataSource({
    required ElectrosurHttpClientFactory clientFactory,
    ElectrosurAccountStatusParser accountStatusParser =
        const ElectrosurAccountStatusParser(),
    ElectrosurConsumptionParser consumptionParser =
        const ElectrosurConsumptionParser(),
    ElectrosurPaymentParser paymentParser = const ElectrosurPaymentParser(),
    ElectrosurSupplyParser supplyParser = const ElectrosurSupplyParser(),
  }) : _clientFactory = clientFactory,
       _accountStatusParser = accountStatusParser,
       _consumptionParser = consumptionParser,
       _paymentParser = paymentParser,
       _supplyParser = supplyParser;

  static const providerId = 'electrosur';

  final ElectrosurHttpClientFactory _clientFactory;
  final ElectrosurAccountStatusParser _accountStatusParser;
  final ElectrosurConsumptionParser _consumptionParser;
  final ElectrosurPaymentParser _paymentParser;
  final ElectrosurSupplyParser _supplyParser;

  @override
  Future<ElectrosurRemoteData> synchronize({
    required String contractNumber,
    required String password,
    required DateTime synchronizedAt,
  }) async {
    final client = _clientFactory();
    try {
      await client.login(contractNumber: contractNumber, password: password);
      final statusResponse = await client.accountStatus();
      final parsedStatus = _accountStatusParser.parse(
        statusResponse.body,
        providerId: providerId,
        synchronizedAt: synchronizedAt,
      );
      final canonicalContract = parsedStatus.account.contractNumber;
      final consumptionResponse = await client.consumptions();
      final consumptions = _consumptionParser.parse(
        consumptionResponse.body,
        providerId: providerId,
        contractNumber: canonicalContract,
        synchronizedAt: synchronizedAt,
      );
      final paymentResponse = await client.payments();
      final payments = _paymentParser.parse(
        paymentResponse.body,
        providerId: providerId,
        contractNumber: canonicalContract,
        synchronizedAt: synchronizedAt,
      );

      var account = parsedStatus.account;
      var supplyAvailable = false;
      final supplyResponse = await client.supply();
      try {
        final supply = _supplyParser.parse(supplyResponse.body);
        account = account.copyWith(
          tariffCode: supply.tariffCode,
          connectionType: supply.connectionType,
          feederType: supply.feederType,
          contractedPower: supply.contractedPower,
          voltageLevel: supply.voltageLevel,
          meterNumber: supply.meterNumber,
        );
        supplyAvailable = true;
      } on ElectricitySectionStructureException {
        // Secondary supply details are optional and cannot invalidate the
        // account status, consumption and payment sections already parsed.
      }

      return ElectrosurRemoteData(
        account: account,
        accountStatus: parsedStatus.status,
        consumptionRecords: consumptions,
        paymentRecords: payments,
        supplyDetailsAvailable: supplyAvailable,
      );
    } finally {
      // There is no verified remote logout endpoint. Closing destroys the
      // in-memory cookie jar and all session state.
      await client.close();
    }
  }
}

class ElectrosurRemoteData {
  ElectrosurRemoteData({
    required this.account,
    required this.accountStatus,
    required List<ElectricityConsumptionRecord> consumptionRecords,
    required List<ElectricityPaymentRecord> paymentRecords,
    required this.supplyDetailsAvailable,
  }) : consumptionRecords = List.unmodifiable(consumptionRecords),
       paymentRecords = List.unmodifiable(paymentRecords);

  final ElectricityAccount account;
  final ElectricityAccountStatus accountStatus;
  final List<ElectricityConsumptionRecord> consumptionRecords;
  final List<ElectricityPaymentRecord> paymentRecords;
  final bool supplyDetailsAvailable;
}
