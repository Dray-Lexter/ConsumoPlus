import 'package:consumo_plus/features/electricity/data/parsers/electrosur_session_parser.dart';
import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';

import 'electrosur_endpoints.dart';
import 'electrosur_request.dart';
import 'electrosur_response.dart';
import 'electrosur_transport.dart';

class ElectrosurHttpClient {
  ElectrosurHttpClient(this._transport);

  final ElectrosurTransport _transport;

  Future<ElectrosurResponse> login({
    required String contractNumber,
    required String password,
  }) async {
    final response = await _transport.send(
      ElectrosurRequest(
        method: 'POST',
        uri: ElectrosurEndpoints.login,
        formFields: {
          'GstrNumeroContrato': contractNumber,
          'GstrClave': password,
        },
      ),
    );
    final destination = response.location == null
        ? null
        : response.uri.resolve(response.location!);
    final hasAuthCookie = response.cookieNames.any(
      (name) => name.toUpperCase() == '.ASPXAUTH',
    );
    if (response.statusCode != 302 ||
        destination?.path != '/' ||
        !hasAuthCookie) {
      throw const ElectricityInvalidCredentialsException();
    }

    final home = await _transport.send(
      ElectrosurRequest(method: 'GET', uri: ElectrosurEndpoints.base),
    );
    if (_returnsToLogin(home) ||
        home.statusCode != 200 ||
        ElectrosurSessionParser.hasLoginForm(home.body)) {
      throw const ElectricityInvalidCredentialsException();
    }
    return home;
  }

  Future<ElectrosurResponse> accountStatus() =>
      _authenticatedGet(ElectrosurEndpoints.accountStatus);

  Future<ElectrosurResponse> consumptions() =>
      _authenticatedGet(ElectrosurEndpoints.consumptions);

  Future<ElectrosurResponse> payments() =>
      _authenticatedGet(ElectrosurEndpoints.payments);

  Future<ElectrosurResponse> supply() =>
      _authenticatedGet(ElectrosurEndpoints.supply);

  Future<ElectrosurResponse> _authenticatedGet(Uri uri) async {
    final response = await _transport.send(
      ElectrosurRequest(method: 'GET', uri: uri),
    );
    if (_returnsToLogin(response) ||
        ElectrosurSessionParser.hasLoginForm(response.body)) {
      throw const ElectricitySessionExpiredException();
    }
    if (response.statusCode >= 500) {
      throw const ElectrosurUnavailableException();
    }
    if (response.statusCode != 200) {
      throw const ElectrosurUnavailableException();
    }
    return response;
  }

  static bool _returnsToLogin(ElectrosurResponse response) {
    final location = response.location;
    if (location != null &&
        response.uri.resolve(location).path.toLowerCase() == '/login') {
      return true;
    }
    return response.uri.path.toLowerCase() == '/login';
  }

  Future<void> close() => _transport.close();
}
