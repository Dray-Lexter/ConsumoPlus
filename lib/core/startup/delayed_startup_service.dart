import 'startup_service.dart';

class DelayedStartupService implements StartupService {
  const DelayedStartupService(this.delay);

  final Duration delay;

  @override
  Future<void> initialize() => Future<void>.delayed(delay);
}
