import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:odu_core/odu_core.dart';

part 'commands.dart';
part 'extensions.dart';

/// Notifies listeners of distinct states and optionally dispatches analytics.
///
/// Managers are owned by the caller, not by this view model.
abstract class ViewModel<T extends ViewModelState>(
  var T _state, {

  /// Overrides [defaultAnalytics]. Null uses the current default at emission.
  final AnalyticsManager? analytics,
}) extends ChangeNotifier {
  /// Shared manager used by view models without an explicit [analytics] manager.
  ///
  /// Configure once at application startup, after initializing the manager.
  /// Changes apply to subsequent emissions, including existing view models.
  /// Assign null to clear the default. Replacing or clearing this value does
  /// not dispose managers or cancel pending events. Tests should restore it.
  static AnalyticsManager? defaultAnalytics;

  /// The current state.
  T get state => _state;

  /// Emits a distinct state and starts its analytics without awaiting providers.
  ///
  /// Initial and equal states do not produce events. States without
  /// [StateAnalyticsMixin] still notify listeners normally.
  @protected
  void emit(T newState) {
    if (newState == _state) {
      return;
    }
    final manager = analytics ?? defaultAnalytics;
    final events = manager != null && newState is StateAnalyticsMixin
        ? newState.analyticsEvents
        : const <AnalyticsEvent>[];
    _state = newState;
    notifyListeners();
    if (manager != null) {
      for (final event in events) {
        unawaited(manager.track(event));
      }
    }
  }
}

/// Base class for immutable states compared by value through [props].
abstract class const ViewModelState() extends Equatable;

/// Opts a state into analytics without automatically exposing [props].
mixin StateAnalyticsMixin on ViewModelState {
  /// Events dispatched when this state is emitted by a configured view model.
  ///
  /// Defaults to one property-free event named after [runtimeType]. Override
  /// with stable event names for production, where type names may be obfuscated.
  /// Return an empty list to omit events. Event creation should be pure.
  List<AnalyticsEvent> get analyticsEvents => [AnalyticsEvent('$runtimeType')];
}
