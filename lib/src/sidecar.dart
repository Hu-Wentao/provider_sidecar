import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider_sidecar/provider_sidecar.dart';

abstract class IEvent {}

class BaseEvent<S> implements IEvent {
  final S state;
  final DebugInfo? debugInfo;

  const BaseEvent(this.state, [this.debugInfo]);

  BaseEvent.debug(this.state, [String? msg, int lineAt = 1])
      : debugInfo = DebugInfo.of(msg, lineAt);
}

abstract class Intent extends IEvent {}

///
/// [DebugInfo.of]
///   [lineAt] 0 表示构造方法被调用的行
///            1 表示构造方法被调用的方法被调用的行（默认）
///           -1 表示关闭StackTrace过滤，打印全部StackTrace
class DebugInfo {
  final String? msg;
  final StackTrace trace;
  final int lineAt;

  const DebugInfo(this.msg, this.trace, this.lineAt);

  DebugInfo.of([this.msg, this.lineAt = 1]) : trace = StackTrace.current;

  ///
  String get onlyStack => trace.lineAt(lineAt, true) ?? '';
}

///
/// 对ChangeNotifier进行包装
/// EX 抛出的异常类型, 便于UI代码展示错误信息
abstract class Sidecar<S, EX> extends ChangeNotifier with SidecarLoggerMx {
  /// 0.1 `构造方法`
  final EX Function(dynamic e, StackTrace s)? onCatch;

  // 配置默认的初始化状态 可以省略`setUninitialized`方法
  Sidecar({
    required this.state,
    this.msg = 'Init with Constructor',
    this.onCatch,
  });

  /// 0.2 配置核心`状态变量`或`get方法`
  S state;
  String msg;

  /// 统一处理异常
  Future<EX?> actWrapper([Function? action, int traceLine = 1]) async {
    try {
      await action?.call();
    } catch (e, s) {
      log('actWrapper.catch# [${e.runtimeType}] ${StackTrace.current.lineAt(traceLine)} \n$e,\n$s');
      return onCatch?.call(e, s);
    }
    return null;
  }

  /// 0.3 配置 `setXxx`方法
  /// [state] 新状态标志，null表示沿用原有状态标志
  /// [m] 状态描述信息，主要用于debug或消息提示
  /// [before] 在配置状态以及[notifyListeners] 之前所执行的方法.
  /// [traceLine] 默认 1，将打印 [setState]方法所在的代码行
  ///   如果代码对[setState]进行过包装，则应当将该值配置为 2或更高
  ///   如果不希望打印[StackTrace]信息,则配置为 -1
  /// set ----------------------------------------------------------------------
  T? setState<T>(
    S? state,
    String m, {
    T? Function()? before,
    int traceLine = 1,
  }) {
    final nState = state ?? this.state;
    log("$nState||${(traceLine > -1) ? StackTrace.current.lineAt(traceLine)?.replaceAll(RegExp(r"^.+\("), r"") : ''}# $m");
    if (m != msg || nState != this.state || before != null) {
      final r = before?.call();
      this.state = nState;
      msg = m;
      notifyListeners();
      return r;
    }
    return null;
  }
}
