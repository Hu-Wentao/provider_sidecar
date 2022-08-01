import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider_sidecar/provider_sidecar.dart';

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

///
/// 对ChangeNotifier进行包装
/// [EX] 抛出的异常类型, 便于UI代码展示错误信息
/// [DATA] 核心贫血数据类, 一般用DTO
abstract class ModelSidecar<DATA, EX> extends Sidecar<ModelState, EX> {
  /// 0.1 `构造方法`
  // 配置默认的初始化状态 可以省略`setUninitialized`方法
  ModelSidecar.build({
    required this.data,
    ModelState state = ModelState.init,
    String msg = 'Init with Constructor',
    EX Function(dynamic e, StackTrace s)? onCatch,
    this.onFetchCall,
    this.onResetCall,
    this.onSubscriptionCall,
    this.onCloseSubsCall,
  }) : super(state: state, msg: msg, onCatch: onCatch);

  ModelSidecar(
    this.data,
    EX Function(dynamic e, StackTrace s)? onCatch, {
    this.onFetchCall,
    this.onResetCall,
    this.onSubscriptionCall,
    this.onCloseSubsCall,
    ModelState state = ModelState.init,
    String msg = 'Init with Constructor',
  }) : super(state: state, msg: msg, onCatch: onCatch);

  /// 0.2 配置核心`数据`(推荐直接使用DTO,或Entity)
  DATA data;

  /// 查看当前Model是否处于贫血状态
  bool get isAnemic => state == ModelState.init;

  bool get isRich => !isAnemic;

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

  T? setInit<T>([String m = "初始状态", T Function()? before]) =>
      setState(ModelState.init, m, before: before);

  T? setActive<T>([String m = "刷新状态...", T Function()? before]) =>
      setState(ModelState.active, m, before: before);

  T? setDone<T>([
    String m = "完成刷新",
    T? Function()? before,
    bool changeState = true,
  ]) =>
      setState(changeState ? ModelState.done : state, m,
          before: () => before?.call());

  /// 如果当前状态已经是 [ModelState.done] || [ModelState.active]
  /// 则保持该状态,否则将设为 [ModelState.done]
  T? setDoneKeepState<T>([String m = "完成刷新", T? Function()? before]) =>
      setState(
          (state == ModelState.done || state == ModelState.active)
              ? state
              : ModelState.done,
          m,
          before: () => before?.call());

  /// === 状态刷新

  /// 开启订阅并获取数据
  /// 先 开启订阅; 后 获取数据,
  /// 可以避免获取数据阻塞时间过长导致没有及时开启订阅
  /// [ModelState.init] -> [ModelState.active]
  Future<EX?> actInitSubscription() async =>
      await actWrapper(() => reqWrapper(() async {
            final active = onSubscriptionCall != null;
            await onSubscriptionCall?.call();
            await onFetchCall?.call(isActive: active);
            setActive(
                "初始化完成(开订阅[${onSubscriptionCall != null}], 获取数据[${onFetchCall != null}])");
          }, accWhen: () => state == ModelState.init));

  /// 关闭订阅并重置数据
  /// 先 关闭订阅; 后 清理缓存状态
  /// ![ModelState.init]   -> [ModelState.init]
  Future<EX?> actCloseReset() async =>
      await actWrapper(() => reqWrapper(() async {
            await onCloseSubsCall?.call();
            await onResetCall?.call();
            setInit(
                "重置完成(关订阅[${onCloseSubsCall != null}], 清理数据[${onResetCall != null}])");
          }, accWhen: () => state != ModelState.init));

  /// 开启状态订阅 (持续刷新数据,保持充血)
  /// ![ModelState.active] -> [ModelState.active]
  Future<EX?> actSubscription() async =>
      await actWrapper(() => reqWrapper(() async {
            await onSubscriptionCall?.call();
            setActive("开订阅[${onSubscriptionCall != null}]");
          }, accWhen: () => state != ModelState.active));

  /// 关闭状态订阅 (停止刷新数据,但保持充血)
  /// [ModelState.active]  -> [ModelState.done]
  Future<EX?> actUnsubscribe() async =>
      await actWrapper(() => reqWrapper(() async {
            await onCloseSubsCall?.call();
            setDone("关订阅[${onCloseSubsCall != null}]");
          }, accWhen: () => state == ModelState.active));

  /// (全量)刷新状态 (单次刷新数据,保持充血)
  /// 先 清理缓存状态; 后 获取状态数据
  ///  any                  -> [ModelState.done]
  Future<EX?> actRefresh({bool isActive = false}) async =>
      await actWrapper(() => reqWrapper(() async {
            await onResetCall?.call();
            await onFetchCall?.call(isActive: isActive);
            setActive(
                "状态刷新完成(清理[${onResetCall != null}], 获取数据[${onFetchCall != null}])");
          }));

  /// 开启订阅流 (增量刷新数据)
  @protected
  FutureOr<void> Function()? onSubscriptionCall;

  /// 关闭订阅流 (停止刷新数据)
  @protected
  FutureOr<void> Function()? onCloseSubsCall;

  /// 获取状态数据 (全量拉取数据)
  /// 对于 数据: 设为null或clear()
  /// 对于 子状态[ModelSidecar] : 根据需要,调用 [actInitSubscription]
  @protected
  FutureOr<void> Function({bool isActive})? onFetchCall;

  /// 清理缓存数据 (清理数据)
  /// 对于 数据: 设为null或clear()
  /// 对于 子状态[ModelSidecar] : 调用 [actCloseReset]
  @protected
  FutureOr<void> Function()? onResetCall;

  /// Deprecated 方法
  /// ----------------------------------------------------------------------
  // 预定义方法: 更新[data]
  // [silence] false表示调用后立即setState; true一般用于在 [onFetch]中调用
  // [state] 取两种状态,
  //   [ModelState.active],表示通过Realtime刷新;
  //   [ModelState.done],表示通过REST刷新
  /// [data] 一般来自DTO, 一个[data]只对应一个[ModelSidecar]
  /// 如果[data]刷新,则应当新建一个[ModelSidecar],替换原有的.
  /// 而不是调用原[ModelSidecar]的[updateData]
  ///   以FamilyModel为例, 其子状态PersonModel的核心数据可以仅仅只是一个 personId
  ///     如果 personId变更,
  ///     则其对应的PersonModel应当随之销毁,重新建立PersonModel进行替换
  /// 如果遇到必须调用[updateData]的情况, 则很可能是因为设计有问题. 如缺少上层状态等
  ///   以UserModel为例,如果要恢复登录用户的状态,
  ///     则应当添加上层状态AppStateModel,用于管理UserModel,而不是在内部调用[updateData]
  @Deprecated('避免调用本方法! data一般不单独变更,应当与Model一一对应')
  @mustCallSuper
  DATA updateData(
    DATA data, {
    bool silence = false,
    ModelState state = ModelState.active,
    String msg = '刷新数据',
  }) {
    this.data = data;
    if (!silence) setState(state, msg);
    return data;
  }

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
@Deprecated('use ModelSidecarWithCall')
mixin ModelStateChangeMx<DATA, EX> on ModelSidecar<DATA, EX> {
  /// 开启订阅并获取数据
  /// 先 开启订阅; 后 获取数据,
  /// 可以避免获取数据阻塞时间过长导致没有及时开启订阅
  /// [ModelState.init] -> [ModelState.active]
  @override
  Future<EX?> actInitSubscription() async =>
      await actWrapper(() => reqWrapper(() async {
            await onSubscription();
            await onFetch(isActive: true);
            setActive("已完成 状态初始化(开订阅+获取)");
          }, accWhen: () => state == ModelState.init));

  /// 关闭订阅并重置数据
  /// 先 关闭订阅; 后 清理缓存状态
  /// ![ModelState.init]   -> [ModelState.init]
  @override
  Future<EX?> actCloseReset() async =>
      await actWrapper(() => reqWrapper(() async {
            await onCloseSubs();
            await onReset();
            setInit("已关闭重置为初始状态(关订阅+清理)");
          }, accWhen: () => state != ModelState.init));

  /// 开启状态订阅 (持续刷新数据,保持充血)
  /// ![ModelState.active] -> [ModelState.active]
  @override
  Future<EX?> actSubscription() async =>
      await actWrapper(() => reqWrapper(() async {
            await onSubscription();
            setActive("已开始状态订阅(开订阅)");
          }, accWhen: () => state != ModelState.active));

  /// 关闭状态订阅 (停止刷新数据,但保持充血)
  /// [ModelState.active]  -> [ModelState.done]
  @override
  Future<EX?> actUnsubscribe() async =>
      await actWrapper(() => reqWrapper(() async {
            await onCloseSubs();
            setDone("已关闭状态订阅(关订阅)");
          }, accWhen: () => state == ModelState.active));

  /// (全量)刷新状态 (单次刷新数据,保持充血)
  /// 先 清理缓存状态; 后 获取状态数据
  ///  any                  -> [ModelState.done]
  @override
  Future<EX?> actRefresh({bool isActive = false}) async =>
      await actWrapper(() => reqWrapper(() async {
            await onReset();
            await onFetch(isActive: isActive);
            setActive("已完成 状态刷新(清理+获取)");
          }));

  /// 开启订阅流 (增量刷新数据)
  @protected
  FutureOr<void> onSubscription();

  /// 关闭订阅流 (停止刷新数据)
  @protected
  FutureOr<void> onCloseSubs();

  /// 获取状态数据 (全量拉取数据)
  /// 对于 数据: 设为null或clear()
  /// 对于 子状态[ModelSidecar] : 根据需要,调用 [actInitSubscription]
  @protected
  FutureOr<void> onFetch({bool isActive = false});

  /// 清理缓存数据 (清理数据)
  /// 对于 数据: 设为null或clear()
  /// 对于 子状态[ModelSidecar] : 调用 [actCloseReset]
  @protected
  FutureOr<void> onReset();

  /// Deprecated 方法
  /// ----------------------------------------------------------------------

  @Deprecated('actUnsubscribe')
  Future<EX?> actCloseSubs() => actUnsubscribe();

  @Deprecated('actCloseReset')
  Future<EX?> actReset() => actCloseReset();

  @Deprecated('actRefresh')
  Future<EX?> actFetch({bool isActive = false}) =>
      actRefresh(isActive: isActive);
}
