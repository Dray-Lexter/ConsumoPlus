import 'package:consumo_plus/core/config/demo_providers.dart';
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
      demoMessage: 'Mensaje',
    );

    expect(identity.id, 'provider-id');
    expect(identity.utilityType, UtilityType.water);
    expect(identity.displayName, 'Proveedor');
  });

  test('demo providers contain only EPS Tacna and Electrosur', () {
    expect(demoProviders, hasLength(2));
    expect(demoProviders.map((provider) => provider.displayName), [
      'EPS Tacna',
      'Electrosur',
    ]);
    expect(demoProviders.map((provider) => provider.utilityType), [
      UtilityType.water,
      UtilityType.electricity,
    ]);
  });
}
