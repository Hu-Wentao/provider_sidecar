part of 'mx.dart';

mixin SidecarLoggerMx {
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
      _lInfo?.call("[$runtimeType]::$message", error, stackTrace);

  /// 打印 shot级别日志,同时附带[StackTrace]
  lgShot(Object? message, [Object? error, StackTrace? stackTrace]) =>
      (_lShot ?? _lInfo)?.call(
          "#[$runtimeType]::${StackTrace.current.lineAt(1)}\n$message",
          error,
          stackTrace);

  @Deprecated("_lInfo")
  get _l => _lInfo;
}
