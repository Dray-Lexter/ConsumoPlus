import 'package:consumo_plus/features/water/data/remote/eps_tacna_endpoints.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_transport.dart';
import 'package:consumo_plus/features/water/data/remote/portal_request.dart';
import 'package:consumo_plus/features/water/data/remote/portal_response.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';

class EpsTacnaHttpClient {
  EpsTacnaHttpClient(this._transport);

  final EpsTacnaTransport _transport;

  Future<PortalResponse> login({
    required String username,
    required String password,
  }) {
    return _send(
      PortalRequest(
        method: 'POST',
        uri: EpsTacnaEndpoints.login,
        formFields: {'usu': username, 'pas': password},
      ),
    );
  }

  Future<PortalResponse> billing() {
    return _send(PortalRequest(method: 'POST', uri: EpsTacnaEndpoints.billing));
  }

  Future<PortalResponse> payments() {
    return _send(
      PortalRequest(method: 'POST', uri: EpsTacnaEndpoints.payments),
    );
  }

  Future<PortalResponse> logout() {
    return _send(PortalRequest(method: 'GET', uri: EpsTacnaEndpoints.logout));
  }

  Future<PortalResponse> _send(PortalRequest request) async {
    final response = await _transport.send(request);
    if (response.statusCode >= 500) {
      throw const PortalUnavailableException();
    }
    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw const PortalUnavailableException();
    }
    return response;
  }

  Future<void> close() => _transport.close();
}
