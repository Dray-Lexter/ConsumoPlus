import 'portal_request.dart';
import 'portal_response.dart';

abstract interface class EpsTacnaTransport {
  Future<PortalResponse> send(PortalRequest request);

  Future<void> close();
}
