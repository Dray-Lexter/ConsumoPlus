import '../models/provider_identity.dart';
import '../models/utility_type.dart';

const epsTacnaProvider = ProviderIdentity(
  id: 'eps-tacna',
  displayName: 'EPS Tacna',
  locality: 'Tacna',
  utilityType: UtilityType.water,
  cardDescription: 'Consulta el espacio demostrativo de tu servicio de agua',
  demoMessage: 'Aquí se preparará la conexión con EPS Tacna.',
);

const electrosurProvider = ProviderIdentity(
  id: 'electrosur',
  displayName: 'Electrosur',
  locality: 'Tacna',
  utilityType: UtilityType.electricity,
  cardDescription:
      'Consulta el espacio demostrativo de tu servicio de electricidad',
  demoMessage: 'Aquí se preparará la conexión con Electrosur.',
);

const demoProviders = <ProviderIdentity>[epsTacnaProvider, electrosurProvider];
