import 'package:equatable/equatable.dart';
import 'package:odu_core/src/domain/guid.dart';

abstract class const Entity({required final GuidId id}) extends Equatable {
  @override
  List<Object?> get props => [id];
}
