part of 'mx.dart';

///
/// Act入口包装
mixin ActEntranceMx<ACT, S, EX> on Sidecar<S, EX> {
  Future<EX?> actEntrance(ACT act) async => await actWrapper(
        () async => onBeforeActEntrance(act) ?? await onActEntrance(act),
      );

  // 自定义防抖节流
  EX? onBeforeActEntrance(ACT act) => null;

  Future<EX?> onActEntrance(ACT act);
}
