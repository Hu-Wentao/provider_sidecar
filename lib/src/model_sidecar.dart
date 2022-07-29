import 'dart:async';

import 'package:flutter/foundation.dart';

///
/// [ModelSidecar]使用指南

///
/// 对于使用REST刷新状态的场景, 只有[init]和[done]两种状态
/// 对于使用Realtime实时刷新的场景, [active]与[done]效果等同
/// Model中的[ModelSidecar.data]存在两种状态
///   anemic: 贫血状态, 一般直接使用DTO
///   rich:   充血状态, 此时DTO已刷新,并且相关的子Model也已经刷新
///
enum ModelState {
  // 仅存在原始数据(DTO), 应当通过REST API获得
  // anemic
  init,
  // 正在接收DTO更新事件, 如果有RealTime API对DTO进行更新的话
  // anemic/rich 正在刷新,实时的
  active,
  // 已停止原始数据的刷新,但仍缓存了状态
  // rich, 非实时
  done,
}

///
/// Model组合指南
/// Model相当于DDD中的聚合根, 但同时整合了Repo的能力, 直接与EntityAccessor交互
/// 在设计上推荐使用mixin 拆分功能
/// 1. 建立抽象类, 继承自[ModelSidecar]
/// 2. 新建DTO 属性, 作为核心数据(核心状态)
/// 3. 新建与DTO业务逻辑相关的实体类的[ModelStateChangeMx] Mixin, 集中管理状态刷新方法
///     根据需要覆写订阅和刷新方法
/// 4.

///
/// 对ChangeNotifier进行包装
/// [EX] 抛出的异常类型, 便于UI代码展示错误信息
/// [DATA] 核心贫血数据类, 一般用DTO
abstract class ModelSidecar<DATA, EX> extends ChangeNotifier {
  @Deprecated("_lInfo")
  get _l => _lInfo;

  // 打印 info日志
  static Function(Object? message, [Object? error, StackTrace? stackTrace])?
      _lInfo;

  // 打印 shot日志
  static Function(Object? message, [Object? error, StackTrace? stackTrace])?
      _lShot;

  static setLogger(
          Function(Object? message, [Object? error, StackTrace? stackTrace])
              log) =>
      _lInfo = log;

  static void setShotLogger(
          Function(Object? message, [Object? error, StackTrace? stackTrace])
              log) =>
      _lShot = log;

  /// 默认Info日志
  log(Object? message, [Object? error, StackTrace? stackTrace]) =>
      lgInfo(message, error: error, stackTrace: stackTrace);

  /// 打印 info级别日志
  lgInfo(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _lInfo?.call("#[$runtimeType]::$message", error, stackTrace);

  /// 打印 shot级别日志,同时附带[StackTrace]
  lgShot(Object? message, [Object? error, StackTrace? stackTrace]) =>
      (_lShot ?? _lInfo)?.call(
          "#[$runtimeType]::$message\n${StackTrace.current}",
          error,
          stackTrace);

  /// 0.1 `构造方法`
  final EX Function(dynamic e, StackTrace s)? onCatch;

  // 配置默认的初始化状态 可以省略`setUninitialized`方法
  ModelSidecar.build({
    required this.data,
    this.state = ModelState.init,
    this.msg = 'Init with Constructor',
    this.onCatch,
  });

  ModelSidecar(
    this.data,
    this.onCatch, {
    this.state = ModelState.init,
    this.msg = 'Init with Constructor',
  });

  /// 0.2 配置核心`数据`(推荐直接使用DTO,或Entity)
  DATA data;
  ModelState state;
  String msg;

  /// 查看当前Model是否处于贫血状态
  bool get isAnemic => state == ModelState.init;

  // 实现类可以附加[data]所引用的实例等等(建议也包装为Model)

  /// 预定义方法: 更新[data]
  /// [state] 取两种状态,
  ///   [ModelState.active],表示通过Realtime刷新;
  ///   [ModelState.done],表示通过REST刷新
  ///
  @mustCallSuper
  DATA updateData(
    DATA data, {
    ModelState state = ModelState.active,
    String msg = '刷新数据',
  }) {
    this.data = data;
    _setState(state, msg);
    return data;
  }

  /// 统一处理异常
  Future<EX?> actWrapper([Function? action]) async {
    try {
      await action?.call();
    } catch (e, s) {
      log('actWrapper# $e,$s');
      return onCatch?.call(e, s);
    }
    return null;
  }

  /// 处理前置触发条件, 防抖节流等
  /// 可选条件参数最多使用1个, 如果使用多个,则只有首个非空参数逻辑生效
  /// 如果不适用任何参数,则默认通过
  T? reqWrapper<T>(
    T? Function() onAccess, {
    List<ModelState>? accWhenAny, // state 必须包含在 list 中
    List<ModelState>? rejWhenAny, // state 不能出现在 list 中
    bool Function()? accWhen, // 返回true即通过
    T? Function()? onReject,
  }) {
    // 默认通过
    bool accessed = true;

    if (accWhenAny != null) {
      accessed = accWhenAny.contains(state);
    } else if (rejWhenAny != null) {
      accessed = !rejWhenAny.contains(state);
    } else if (accWhen != null) {
      accessed = accWhen();
    }

    if (accessed) {
      return onAccess.call();
    } else {
      log("reqWrapper#已拒绝请求#状态[$state],[$msg]");
      return onReject?.call();
    }
  }

  /// 0.3 配置 `setXxx`方法
  /// set ----------------------------------------------------------------------

  T? _setState<T>(ModelState state, String m, {T? Function()? before}) {
    log("_setState($state, $m)");
    if (m != msg || state != this.state || before != null) {
      final r = before?.call();
      this.state = state;
      msg = m;
      notifyListeners();
      return r;
    }
    return null;
  }

  T? setInit<T>([String m = "初始状态", T Function()? before]) =>
      _setState(ModelState.init, m, before: before);

  T? setActive<T>([String m = "刷新状态...", T Function()? before]) =>
      _setState(ModelState.active, m, before: before);

  T? setDone<T>([
    String m = "完成刷新",
    T? Function()? before,
    bool changeState = true,
  ]) =>
      _setState(changeState ? ModelState.done : state, m,
          before: () => before?.call());

  /// 如果当前状态已经是 [ModelState.done] || [ModelState.active]
  /// 则保持该状态,否则将设为 [ModelState.done]
  T? setDoneKeepState<T>([String m = "完成刷新", T? Function()? before]) =>
      _setState(
          (state == ModelState.done || state == ModelState.active)
              ? state
              : ModelState.done,
          m,
          before: () => before?.call());

  /// Deprecated 方法
  /// ----------------------------------------------------------------------

  @Deprecated('setInit')
  T? setUninitialized<T>([String m = "初始状态", T Function()? before]) =>
      setInit(m, before);

  @Deprecated('setRefresh')
  T? setInitializing<T>([String m = "刷新状态...", T Function()? before]) =>
      setActive(m, before);

  @Deprecated('setDone')
  T? setInitialized<T>([String m = "完成刷新", T Function()? before]) =>
      setDone(m, before);
}

///
/// 包装Model的状态变更方法
mixin ModelStateChangeMx<DATA, EX> on ModelSidecar<DATA, EX> {
  /// (仅用于初始化)
  /// 先 开始持续订阅; 后 获取全部数据
  /// [ModelState.init] -> [ModelState.active]
  Future<EX?> actInitSubscription() async =>
      await actWrapper(() => reqWrapper(() async {
            // 先 订阅更新
            await onSubscription();
            // 后 获取全部数据
            await onFetch(isActive: true);
            setActive("已完成 状态初始化(开订阅+获取)");
          }, accWhen: () => state == ModelState.init));

  /// (增量) 开始持续订阅状态 (持续刷新数据,保持充血)
  /// 仅开启订阅
  /// ![ModelState.active] -> [ModelState.active]
  Future<EX?> actSubscription() async =>
      await actWrapper(() => reqWrapper(() async {
            await onSubscription();
            setActive("已开始状态订阅(开订阅)");
          }, accWhen: () => state != ModelState.active));

  /// 关闭状态订阅 (停止刷新数据,但保持充血)
  /// 仅关闭订阅
  /// [ModelState.active]  -> [ModelState.done]
  Future<EX?> actCloseSubs() async =>
      await actWrapper(() => reqWrapper(() async {
            await onCloseSubs();
            setDone("已关闭状态订阅(关订阅)");
          }, accWhen: () => state == ModelState.active));

  /// (全量)刷新状态 (单次刷新数据,保持充血)
  /// 先 清理缓存状态; 后 获取状态数据
  ///  any                  -> [ModelState.done]
  Future<EX?> actFetch({bool isActive = false}) async =>
      await actWrapper(() => reqWrapper(() async {
            await onReset();
            await onFetch(isActive: isActive);
            setActive("已完成 状态刷新(清理+获取)");
          }));

  /// 重置状态 (清理充血数据, 充血->贫血)
  /// 先 关闭订阅; 后 清理缓存状态
  /// ![ModelState.init]   -> [ModelState.init]
  Future<EX?> actReset() async => await actWrapper(() => reqWrapper(() async {
        await onCloseSubs();
        await onReset();
        setInit("已关闭重置为初始状态(关订阅+清理)");
      }, accWhen: () => state != ModelState.init));

  /// 开启订阅流 (增量刷新数据)
  @protected
  FutureOr<void> onSubscription();

  /// 关闭订阅流 (停止刷新数据)
  @protected
  FutureOr<void> onCloseSubs();

  /// 获取状态数据 (全量拉取数据)
  @protected
  FutureOr<void> onFetch({bool isActive = false});

  /// 清理缓存状态 (清理数据)
  @protected
  FutureOr<void> onReset();
}
