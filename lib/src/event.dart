part of 'sidecar.dart';

abstract class IEvent {}

class BaseEvent<S> implements IEvent {
  final S state;
  final DebugInfo? debugInfo;

  const BaseEvent(this.state, [this.debugInfo]);

  BaseEvent.debug(this.state, [String? msg, int lineAt = 1])
      : debugInfo = DebugInfo.of(msg, lineAt);
}

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
