import 'dart:async';

import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    final previous = ViewModel.defaultAnalytics;
    ViewModel.defaultAnalytics = null;
    addTearDown(() => ViewModel.defaultAnalytics = previous);
  });

  test('existing view models use and follow the shared default', () async {
    final first = _Provider();
    final second = _Provider();
    final model = _Model(const _Plain(0));
    final other = _Model(const _Plain(0));
    addTearDown(model.dispose);
    addTearDown(other.dispose);

    ViewModel.defaultAnalytics = AnalyticsManager([first]);
    model.update(const _Tracked(1));
    other.update(const _Tracked(1));
    ViewModel.defaultAnalytics = AnalyticsManager([second]);
    model.update(const _Tracked(2));
    ViewModel.defaultAnalytics = null;
    model.update(const _Tracked(3));
    await Future<void>.delayed(Duration.zero);

    expect(first.events, hasLength(4));
    expect(second.events, hasLength(2));
    expect(model.state, const _Tracked(3));
  });

  test('explicit manager takes precedence over the shared default', () async {
    final shared = _Provider();
    final local = _Provider();
    ViewModel.defaultAnalytics = AnalyticsManager([shared]);
    final model = _Model(
      const _Plain(0),
      analytics: AnalyticsManager([local]),
    );
    addTearDown(model.dispose);
    model.update(const _Tracked(1));
    await Future<void>.delayed(Duration.zero);

    expect(shared.events, isEmpty);
    expect(local.events, hasLength(2));
  });

  test('only distinct opted-in states produce events', () async {
    final provider = _Provider();
    final model = _Model(
      const _Plain(0),
      analytics: AnalyticsManager([provider]),
    );
    addTearDown(model.dispose);
    var notifications = 0;
    model.addListener(() => notifications++);
    expect(provider.events, isEmpty);

    model.update(const _Plain(1));
    expect(provider.events, isEmpty);
    model.update(const _Tracked(2));
    model.update(const _Tracked(2));
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 2);
    expect(provider.events.map((event) => event.name), ['search', 'loading']);
    expect(provider.events.first.properties, {'count': 2});
  });

  test('default event does not expose equality properties', () {
    final event = const _DefaultTracked('private').analyticsEvents.single;
    expect(event.name, '_DefaultTracked');
    expect(event.properties, isEmpty);
  });

  test('analytics is optional and initial tracked state is not sent', () {
    final model = _Model(const _Tracked(0));
    addTearDown(model.dispose);
    model.update(const _Tracked(1));
    expect(model.state, const _Tracked(1));
    final provider = _Provider();
    final configured = _Model(
      const _Tracked(0),
      analytics: AnalyticsManager([provider]),
    );
    addTearDown(configured.dispose);
    expect(provider.events, isEmpty);
  });

  test(
    'hidden properties are removed before reaching every provider',
    () async {
      final source = <String, Object?>{'email': 'private', 'count': 1};
      final event = AnalyticsEvent(
        'search',
        properties: source,
        hiddenProperties: {'email', 'missing'},
      );
      source['email'] = 'changed';
      source['count'] = 2;
      expect(event.properties, {'count': 1});
      expect(() => event.properties['email'] = 'leak', throwsUnsupportedError);
      final first = _Provider();
      final second = _Provider();
      await AnalyticsManager([first, second]).track(event);
      expect(first.events.single.properties, {'count': 1});
      expect(second.events.single.properties, {'count': 1});
    },
  );

  test('slow and failing providers do not block state notifications', () async {
    final gate = Completer<void>();
    final slow = _Provider(gate: gate);
    final failing = _Provider(fails: true);
    final healthy = _Provider();
    final model = _Model(
      const _Plain(0),
      analytics: AnalyticsManager([slow, failing, healthy]),
    );
    addTearDown(model.dispose);
    var notified = false;
    model.addListener(() => notified = true);
    model.update(const _Tracked(1));
    expect(notified, isTrue);
    expect(model.state, const _Tracked(1));
    expect(healthy.events, hasLength(2));
    gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(slow.events, hasLength(2));
  });
}

final class _Model(super.state, {super.analytics})
    extends ViewModel<ViewModelState> {
  void update(ViewModelState value) => emit(value);
}

final class const _Plain(final int value) extends ViewModelState {
  @override
  List<Object?> get props => [value];
}

final class const _Tracked(final int value)
    extends ViewModelState
    with StateAnalyticsMixin {
  @override
  List<Object?> get props => [value];

  @override
  List<AnalyticsEvent> get analyticsEvents => [
    AnalyticsEvent(
      'search',
      properties: {'count': value, 'email': 'private'},
      hiddenProperties: {'email'},
    ),
    AnalyticsEvent('loading'),
  ];
}

final class const _DefaultTracked(final String secret)
    extends ViewModelState
    with StateAnalyticsMixin {
  @override
  List<Object?> get props => [secret];
}

final class _Provider({final Completer<void>? gate, final bool fails = false})
    implements AnalyticsProvider {
  final List<AnalyticsEvent> events = [];

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (fails) {
      throw StateError('provider failed');
    }
    if (gate != null) {
      await gate!.future;
    }
    events.add(event);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> dispose() async {}
}
