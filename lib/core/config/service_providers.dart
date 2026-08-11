import '../models/provider_identity.dart';
import '../models/utility_type.dart';

const epsTacnaProvider = ProviderIdentity(
  id: 'eps-tacna',
  displayName: 'EPS Tacna',
  locality: 'Tacna',
  utilityType: UtilityType.water,
  cardDescription: 'Consulta tus recibos, pagos y datos del suministro',
  availabilityMessage: 'La conexión con EPS Tacna está disponible.',
);

const electrosurProvider = ProviderIdentity(
  id: 'electrosur',
  displayName: 'Electrosur',
  locality: 'Tacna',
  utilityType: UtilityType.electricity,
  cardDescription: 'Consulta tu estado de cuenta, consumos y pagos',
  availabilityMessage: 'La conexión con Electrosur está disponible.',
);

const serviceProviders = <ProviderIdentity>[
  epsTacnaProvider,
  electrosurProvider,
];
