import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider_sidecar/provider_sidecar.dart';
part 'event.dart';

/// since v1.5.2
/// 可以取代 [SidecarProvider]
/// [SidecarModel] 本身就是数据，只不过[ChangeNotifier]赋予它通知UI刷新的能力
/// [SidecarProvider]则更像是一个数据的提供器，代理数据类向UI发出通知。
abstract class SidecarModel<EVT, ID> extends MsgSidecar with SidecarEvtMx<EVT> {
  final ID id;
  SidecarModel({required this.id});

  /// @override
  /// FutureOr<void> onEvent(evt) {
  ///   // do some logic ...
  ///   // setState( ... )     // notify refresh UI
  ///   // add( ... )          // add another event
  /// }
}

abstract class MsgSidecar extends ChangeNotifier with SidecarLoggerMx {
  MsgSidecar({this.msg = 'Init with Constructor'});

  String msg;

  T? setState<T>(
    String m, {
    T? Function()? before,
    int traceLine = 1,
  }) {
    log("${(traceLine > -1) ? StackTrace.current.lineAt(traceLine)?.replaceAll(RegExp(r"^.+\("), r"") : ''}# $m");
    if (m != msg || before != null) {
      final r = before?.call();
      msg = m;
      notifyListeners();
      return r;
    }
    return null;
  }
}

@Deprecated('use MsgSidecar, use final ID id instead S state')
abstract class BaseSidecar<S> extends ChangeNotifier with SidecarLoggerMx {
  // 配置默认的初始化状态 可以省略`setUninitialized`方法
  BaseSidecar({
    required this.state,
    this.msg = 'Init with Constructor',
  });

  /// 0.2 配置核心`状态变量`或`get方法`
  S state;
  String msg;

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

///
/// 对ChangeNotifier进行包装
/// EX 抛出的异常类型, 便于UI代码展示错误信息
@Deprecated('使用BaseSidecar, 使用onEvent和onError替代actWrapper')
abstract class Sidecar<S, EX> extends BaseSidecar<S> {
  /// 0.1 `构造方法`
  final EX Function(dynamic e, StackTrace s)? onCatch;

  // 配置默认的初始化状态 可以省略`setUninitialized`方法
  Sidecar({
    required super.state,
    super.msg = 'Init with Constructor',
    this.onCatch,
  });

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
}
