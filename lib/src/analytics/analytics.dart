import 'dart:developer' as developer;

final class AnalyticsEvent(
  final String name, {
  final Map<String, dynamic> properties = const {},
});

abstract interface class AnalyticsProvider() {
  Future<void> initialize();

  Future<void> track(AnalyticsEvent event);

  Future<void> identify(String userId);

  Future<void> reset();

  Future<void> dispose();
}

final class AnalyticsManager(List<AnalyticsProvider> providers) {
  this : _providers = List.unmodifiable(providers);

  final List<AnalyticsProvider> _providers;

  Future<void> initialize() async {
    await _dispatch((provider) => provider.initialize());
  }

  Future<void> track(AnalyticsEvent event) =>
      _dispatch((provider) => provider.track(event));

  Future<void> identify(String userId) =>
      _dispatch((provider) => provider.identify(userId));

  Future<void> reset() => _dispatch((provider) => provider.reset());

  Future<void> dispose() => _dispatch((provider) => provider.dispose());

  Future<void> _dispatch(
    Future<void> Function(AnalyticsProvider provider) action,
  ) async {
    await Future.wait(
      _providers.map((provider) async {
        try {
          await action(provider);
        } on Object catch (error, stackTrace) {
          _logProviderError(provider, error, stackTrace);
        }
      }),
    );
  }

  void _logProviderError(
    AnalyticsProvider provider,
    Object error,
    StackTrace stackTrace,
  ) {
    developer.log(
      'Falha no provider de analytics ${provider.runtimeType}.',
      name: 'odu_core.analytics',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
