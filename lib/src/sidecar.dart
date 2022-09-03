import 'package:flutter/foundation.dart';
import 'package:provider_sidecar/provider_sidecar.dart';
import 'package:provider_sidecar/src/utils.dart';

/// 使用指南
/// 0. 创建类与依赖注入
/// 继承`ProviderSidecar`并实现方法;
/// 添加注解, 运行 `dart run build_runner watch` 生成DI代码;
/// ```dart
/// @lazySingleton
/// class DeviceNicknameProvider extends ProviderSidecar {
///   // 0.1 `构造方法`与 `final属性`
///   // 如`final ApiClient client;` 一般是从IoC中注入的基础设施, 如网络API, 本地存储等
///   // 注意: DI会尝试注入构造函数的所有参数, 包括位置和可选参数
///
///   // 0.2 配置核心`状态变量`或`get方法`
///   // 如 `Process? proc;` 和与之对应的 bool get isRunning => proc!=null;
///
///   // 0.3 配置 `setXxx`方法
///   // 如`setUninitialized`表示设定内部状态,是瞬时的, 表示`设为..`
///   // 此时状态通常是完成时, 如 `initialized`
///
///   // **推荐使用**
///   // 0.3.1 `reqWrapper` 的使用
///   // 对于自定以的`setXxx`方法, 可以通过 `reqWrapper`装包业务逻辑
///
///   // before:
///   setStart() => setInitialized("正在启动..");
///
///   // after:
///   setStart() => reqWrapper(
///         () => setInitialized("正在启动.."), // setXxx的简单业务逻辑
///         accContain: [SidecarState.initialized], // 通过条件
///         onReject: () => throw "尚未完成初始化, 当前状态[$state]",
///       );
///
///   // 0.4 配置 `actXxx`方法
///   // 如`actInitializing`表示开始耗时方法,是耗时的, 表示`开始..`
///   // 此时状态通常是进行时, 如 `initializing`
///
///   // 0.4.1 `onInitializing`是`ProviderSidecar`提供的默认的act方法的包装
///   // 覆写该方法后, 只需要调用 setXxx方法即可
///   @override
///   onInitializing() async {
///     try {
///     // ... logic
///     setInitialized();
///     } catch(e){
///       if(...) setUninitialized();
///       rethrow;
///     }
///   }
///
///   // 0.4.2 自定义`actXxx`方法
///   // 可以参照`ProviderSidecar`的`actInitializing`编写,
///   // 注意返回值类型最好是 Exception类型, 便于Dialog或SnackBar处理抛出的异常
///
///   // **推荐使用**
///   // 0.4.2.1 `actWrapper` 的使用
///   // 对于自定义的 `actXxx`方法, 可以使用 actWrapper 对业务逻辑进行包装,
///   // 以自动实现对 异常的 try..catch处理
///
///   // before:
///   Future<EX?> actRun() async {
///   // 方法体内部需要自行处理try..catch,否则无法捕获和处理抛出的异常
///     // 进入方法后立即切换 state
///     setStart();
///     // ... 业务逻辑 ... 包含异常的抛出
///   }
///
///   // after:
///   Future<EX?> actRun() => actWrapper(() async {
///     // 进入方法后立即切换 state
///     setStart();
///     // ... 业务逻辑 ... 包含异常的抛出
///   });
/// ```
///
/// 1. Provider注册
/// 即注册到`MultiProvider`中
/// - 如果Provider使用默认的初始化值(构造方法), 并且没有notify的需求,则无需调用`setUninitialized`方法
/// - 推荐使用构造方法进行初始化
///```dart
///  ChangeNotifierProvider(
///      create: (c) => sl<DeviceNicknameProvider>()..setUninitialized()),
///  )
/// ```
///
/// 2. 使用
/// ```dart
/// Consumer<DeviceNicknameProvider>(
///   builder: (_, p, __) {
///   // ...
///   }
/// )
///```
///
/// 3. <可选> 指定抛出异常类型
/// `BaseException` 可以是App内异常的基类, 以便UI统一处理(弹出Dialog,Toast等)
/// ```dart
/// class MySidecar extends ProviderSidecar<BaseException>{
///   @override
///   onInitializing() {
///     // ...
///   }
/// }
/// ```
/// BaseException 示例 (来自 get_arch_core package)
/// ```dart
/// class BaseException {
///   final String msg; // 直接向用户展示
///   final String debugInfo; // 用于问题反馈，帮助定位BUG的信息，可以用stacktrace填充
///
///   BaseException(this.msg, {this.debugInfo = ''});
///
///   @override
///   String toString({int maxInfoLen = 100}) =>
///       'BaseException{msg: $msg, debugInfo: ${(debugInfo.length > maxInfoLen) ? '${debugInfo.substring(0, maxInfoLen)}...' : debugInfo}}';
/// }
/// ```
///

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
  Future<EX?> actWrapper([Function? action]) async {
    try {
      await action?.call();
    } catch (e, s) {
      log('actWrapper.catch# [${e.runtimeType}] ${StackTrace.current.parentLineBy('.actWrapper')} \n$e,\n$s');
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
