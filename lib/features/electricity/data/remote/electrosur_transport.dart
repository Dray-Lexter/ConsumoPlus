import 'electrosur_request.dart';
import 'electrosur_response.dart';

abstract interface class ElectrosurTransport {
  Future<ElectrosurResponse> send(ElectrosurRequest request);

  Future<void> close();
}
