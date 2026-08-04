import 'startup_service.dart';

class DemoStartupService implements StartupService {
  const DemoStartupService(this.delay);

  final Duration delay;

  @override
  Future<void> initialize() => Future<void>.delayed(delay);
}
