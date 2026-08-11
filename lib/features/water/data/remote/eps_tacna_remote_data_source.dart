import 'package:consumo_plus/features/water/data/parsers/account_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/billing_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/payment_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/session_page_parser.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_http_client.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';

typedef EpsTacnaHttpClientFactory = EpsTacnaHttpClient Function();

abstract interface class EpsTacnaRemoteSource {
  Future<EpsTacnaRemoteData> synchronize({
    required String username,
    required String password,
    required DateTime synchronizedAt,
  });
}

class EpsTacnaRemoteDataSource implements EpsTacnaRemoteSource {
  const EpsTacnaRemoteDataSource({
    required EpsTacnaHttpClientFactory clientFactory,
    AccountParser accountParser = const AccountParser(),
    BillingParser billingParser = const BillingParser(),
    PaymentParser paymentParser = const PaymentParser(),
  }) : _clientFactory = clientFactory,
       _accountParser = accountParser,
       _billingParser = billingParser,
       _paymentParser = paymentParser;

  static const providerId = 'eps-tacna';

  final EpsTacnaHttpClientFactory _clientFactory;
  final AccountParser _accountParser;
  final BillingParser _billingParser;
  final PaymentParser _paymentParser;

  @override
  Future<EpsTacnaRemoteData> synchronize({
    required String username,
    required String password,
    required DateTime synchronizedAt,
  }) async {
    final client = _clientFactory();
    var authenticated = false;
    try {
      final loginResponse = await client.login(
        username: username,
        password: password,
      );
      if (!SessionPageParser.isAuthenticated(loginResponse.body)) {
        throw const InvalidCredentialsException();
      }
      authenticated = true;

      final account = _accountParser.parse(
        loginResponse.body,
        providerId: providerId,
        customerCode: username,
        synchronizedAt: synchronizedAt,
      );
      final billingResponse = await client.billing();
      late final WaterAccount accountWithSupplyDetails;
      try {
        accountWithSupplyDetails = _accountParser.withSupplyDetails(
          billingResponse.body,
          account: account,
        );
      } on SessionExpiredException {
        rethrow;
      } on UnexpectedPortalStructureException {
        throw const BillingHistoryStructureException();
      }
      late final List<BillingRecord> billingRecords;
      try {
        billingRecords = _billingParser.parse(
          billingResponse.body,
          providerId: providerId,
          customerCode: accountWithSupplyDetails.customerCode,
          synchronizedAt: synchronizedAt,
        );
      } on SessionExpiredException {
        rethrow;
      } on UnexpectedPortalStructureException {
        throw const BillingHistoryStructureException();
      }
      final paymentResponse = await client.payments();
      late final List<PaymentRecord> paymentRecords;
      try {
        paymentRecords = _paymentParser.parse(
          paymentResponse.body,
          providerId: providerId,
          customerCode: accountWithSupplyDetails.customerCode,
          synchronizedAt: synchronizedAt,
        );
      } on SessionExpiredException {
        rethrow;
      } on UnexpectedPortalStructureException {
        throw const PaymentHistoryStructureException();
      }

      return EpsTacnaRemoteData(
        account: accountWithSupplyDetails,
        billingRecords: billingRecords,
        paymentRecords: paymentRecords,
      );
    } finally {
      if (authenticated) {
        try {
          await client.logout();
        } on Object {
          // The local in-memory session is still destroyed by close().
        }
      }
      await client.close();
    }
  }
}

class EpsTacnaRemoteData {
  EpsTacnaRemoteData({
    required this.account,
    required List<BillingRecord> billingRecords,
    required List<PaymentRecord> paymentRecords,
  }) : billingRecords = List.unmodifiable(billingRecords),
       paymentRecords = List.unmodifiable(paymentRecords);

  final WaterAccount account;
  final List<BillingRecord> billingRecords;
  final List<PaymentRecord> paymentRecords;
}
