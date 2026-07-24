/// Bridges Dio auth errors ↔ AuthNotifier without Riverpod cycles.
class AuthSessionCoordinator {
  Future<String?> Function()? refresher;
  Future<void> Function()? onExpired;

  bool _refreshing = false;
  Future<String?>? _inFlight;

  Future<String?> refreshAccessToken() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final run = () async {
      if (_refreshing) return null;
      final fn = refresher;
      if (fn == null) return null;
      _refreshing = true;
      try {
        return await fn();
      } finally {
        _refreshing = false;
        _inFlight = null;
      }
    }();

    _inFlight = run;
    return run;
  }

  Future<void> notifyExpired() async {
    final fn = onExpired;
    if (fn == null) return;
    await fn();
  }
}

final authSessionCoordinator = AuthSessionCoordinator();
