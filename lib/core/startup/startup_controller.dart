import 'package:flutter/foundation.dart';

import 'startup_service.dart';

enum StartupStatus { idle, initializing, success, failure }

class StartupController extends ChangeNotifier {
  StartupController(this._service);

  final StartupService _service;
  Future<void>? _inFlight;
  StartupStatus _status = StartupStatus.idle;
  Object? _error;
  bool _isDisposed = false;

  StartupStatus get status => _status;
  Object? get error => _error;

  Future<void> initialize() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<void> retry() => initialize();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _run() async {
    _status = StartupStatus.initializing;
    _error = null;
    notifyListeners();
    try {
      await _service.initialize();
      _status = StartupStatus.success;
    } catch (error) {
      _error = error;
      _status = StartupStatus.failure;
    }
    if (!_isDisposed) notifyListeners();
  }
}
