import 'package:flutter/foundation.dart';

import '../domain/upcoming_dates_calculator.dart';
import 'upcoming_dates_source.dart';
import 'upcoming_dates_state.dart';

typedef UpcomingDatesControllerFactory =
    Future<UpcomingDatesController> Function();

class UpcomingDatesController extends ChangeNotifier {
  UpcomingDatesController({
    required UpcomingDatesSource source,
    DateTime Function()? clock,
    UpcomingDatesCalculator calculator = const UpcomingDatesCalculator(),
  }) : _source = source,
       _clock = clock ?? DateTime.now,
       _calculator = calculator;

  final UpcomingDatesSource _source;
  final DateTime Function() _clock;
  final UpcomingDatesCalculator _calculator;

  UpcomingDatesState _state = UpcomingDatesState();
  var _disposed = false;

  UpcomingDatesState get state => _state;

  Future<void> refresh() async {
    _setState(UpcomingDatesState(isLoading: true, schedules: _state.schedules));
    try {
      final input = await _source.load();
      _setState(
        UpcomingDatesState(
          schedules: _calculator.build(input: input, now: _clock()),
        ),
      );
    } on Object {
      _setState(UpcomingDatesState());
    }
  }

  void _setState(UpcomingDatesState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
