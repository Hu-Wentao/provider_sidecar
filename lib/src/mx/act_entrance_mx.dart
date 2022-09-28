part of 'mx.dart';

///
/// Act入口包装
mixin ActEntranceMx<ACT, S, EX> on Sidecar<S, EX> {
  Future<EX?> actEntrance(ACT act) async => await actWrapper(
        () async => onBeforeActEntrance(act) ?? await onActEntrance(act),
        2,
      );

  /// 自定义防抖节流
  /// 可以直接抛出异常（将会打印StackTrace）
  /// 也可以返回异常 (不做处理，建议返回const值)
  EX? onBeforeActEntrance(ACT act) => null;

  dynamic onActEntrance(ACT act);
}