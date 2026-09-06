import 'package:flutter/foundation.dart';
import 'package:odu_core/odu_core.dart';

part 'commands.dart';
part 'extensions.dart';

abstract class ViewModel<T extends ViewModelState>(var T _state)
    extends ChangeNotifier {
  T get state => _state;

  @protected
  void emit(T newState) {
    if (newState == _state) {
      return;
    }
    _state = newState;
    notifyListeners();
  }
}

/// Base class for immutable states compared by value through [props].
abstract class const ViewModelState() extends Equatable;
