import 'package:provider_sidecar/provider_sidecar.dart';

/// 子状态字段包装类
/// <慎用，可能会被移除>
class SubState<T> {
  SubState({
    required this.parent,
    required T field,
    this.memo = '',
  }) : _field = field;

  final Sidecar parent;
  final String memo;
  T _field;

  setField(T f) {
    _field = field;
    parent.setState(null, '更新[$memo]', traceLine: 2);
  }

  T get field => _field!;

  T call() => field;
}
