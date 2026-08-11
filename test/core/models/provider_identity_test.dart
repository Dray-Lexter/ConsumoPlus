import 'package:consumo_plus/core/config/service_providers.dart';
import 'package:consumo_plus/core/models/provider_identity.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProviderIdentity stores typed immutable provider data', () {
    const identity = ProviderIdentity(
      id: 'provider-id',
      displayName: 'Proveedor',
      locality: 'Tacna',
      utilityType: UtilityType.water,
      cardDescription: 'Descripción',
      availabilityMessage: 'Mensaje',
    );

    expect(identity.id, 'provider-id');
    expect(identity.utilityType, UtilityType.water);
    expect(identity.displayName, 'Proveedor');
  });

  test('service providers contain only EPS Tacna and Electrosur', () {
    expect(serviceProviders, hasLength(2));
    expect(serviceProviders.map((provider) => provider.displayName), [
      'EPS Tacna',
      'Electrosur',
    ]);
    expect(serviceProviders.map((provider) => provider.utilityType), [
      UtilityType.water,
      UtilityType.electricity,
    ]);
  });
}
