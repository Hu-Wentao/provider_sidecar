import 'dart:async';

/// 子状态字段包装类
/// <实验性功能，可能会被移除>
class SubState<T> {
  SubState({
    required T? value,
    this.memo = '',
    this.doOnSet,
    this.doOnFetch,
  }) : _value = value;

  final String memo;
  T? _value;

  void setValue(T v) {
    if (_value == v) return;
    doOnSet?.call(v);
    _value = v;
  }

  T get value => _value!;

  T call() => value;

  Future<T> Function()? doOnFetch;
  Function(T v)? doOnSet;

  //
  Future onFetch() async {
    final r = await doOnFetch?.call();
    if (r == null) return null;
    setValue(r);
  }

  void onReset() => _value = null;
}
