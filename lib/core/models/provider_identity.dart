import 'utility_type.dart';

class ProviderIdentity {
  const ProviderIdentity({
    required this.id,
    required this.displayName,
    required this.locality,
    required this.utilityType,
    required this.cardDescription,
    required this.availabilityMessage,
  });

  final String id;
  final String displayName;
  final String locality;
  final UtilityType utilityType;
  final String cardDescription;
  final String availabilityMessage;
}
