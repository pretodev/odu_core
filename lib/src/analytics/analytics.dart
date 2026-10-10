import 'dart:developer' as developer;

/// An event with explicitly selected properties for analytics providers.
///
/// [hiddenProperties] removes top-level keys before storing the payload. To
/// hide nested personal data, exclude its containing top-level property.
final class AnalyticsEvent(
  /// The event name. Prefer stable names independent of runtime types.
  final String name, {
  Map<String, Object?> properties = const {},
  Set<String> hiddenProperties = const {},
}) {
  this
    : properties = Map.unmodifiable({
        for (final entry in properties.entries)
          if (!hiddenProperties.contains(entry.key)) entry.key: entry.value,
      });

  /// The filtered, unmodifiable payload; nested values should be immutable.
  final Map<String, Object?> properties;
}

/// Adapter for an analytics backend.
abstract interface class AnalyticsProvider() {
  /// Initializes the backend.
  Future<void> initialize();

  /// Sends a filtered event to the backend.
  Future<void> track(AnalyticsEvent event);

  /// Associates subsequent events with a user.
  Future<void> identify(String userId);

  /// Clears the current user association.
  Future<void> reset();

  /// Releases backend resources.
  Future<void> dispose();
}

/// Dispatches operations to providers independently, logging provider errors.
///
/// The owner is responsible for initialization and disposal.
final class AnalyticsManager(List<AnalyticsProvider> providers) {
  this : _providers = List.unmodifiable(providers);

  final List<AnalyticsProvider> _providers;

  /// Initializes all providers.
  Future<void> initialize() async {
    await _dispatch((provider) => provider.initialize());
  }

  /// Sends an event to all providers.
  Future<void> track(AnalyticsEvent event) =>
      _dispatch((provider) => provider.track(event));

  /// Identifies the user in all providers.
  Future<void> identify(String userId) =>
      _dispatch((provider) => provider.identify(userId));

  /// Resets all providers.
  Future<void> reset() => _dispatch((provider) => provider.reset());

  /// Disposes all providers.
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
