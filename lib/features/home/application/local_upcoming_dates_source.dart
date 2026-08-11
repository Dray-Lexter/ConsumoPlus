import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';

import '../domain/upcoming_dates_models.dart';
import 'upcoming_dates_source.dart';

typedef WaterSnapshotLoader = Future<WaterSnapshot?> Function();
typedef ElectricitySnapshotLoader = Future<ElectricitySnapshot?> Function();

class LocalUpcomingDatesSource implements UpcomingDatesSource {
  const LocalUpcomingDatesSource({
    required WaterSnapshotLoader loadWater,
    required ElectricitySnapshotLoader loadElectricity,
  }) : _loadWater = loadWater,
       _loadElectricity = loadElectricity;

  final WaterSnapshotLoader _loadWater;
  final ElectricitySnapshotLoader _loadElectricity;

  @override
  Future<UpcomingDatesInput> load() async {
    final snapshots = await Future.wait<Object?>([
      _loadWater(),
      _loadElectricity(),
    ]);
    final water = snapshots[0] as WaterSnapshot?;
    final electricity = snapshots[1] as ElectricitySnapshot?;
    final accountStatus = electricity?.latestAccountStatus;
    return UpcomingDatesInput(
      waterConnected: water != null,
      electricityConnected: electricity != null,
      electricityIssueDate: accountStatus?.issueDate,
      electricityDueDate: accountStatus?.dueDate,
    );
  }
}
