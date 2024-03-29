import 'package:flutter/foundation.dart';
import 'package:provider_sidecar/src/mx/mx.dart';

import 'sidecar.dart';

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

/// 状态
enum SidecarState {
  uninitialized, // 未初始化
  initializing, // 正在初始化
  initialized, // 初始化完毕
}

///
/// 对ChangeNotifier进行包装
/// EX 抛出的异常类型, 便于UI代码展示错误信息
@Deprecated('建议使用 ModelSidecar')
abstract class ProviderSidecar<EX> extends Sidecar<SidecarState, EX> {
  // 配置默认的初始化状态 可以省略`setUninitialized`方法
  ProviderSidecar({
    SidecarState state = SidecarState.uninitialized,
    String msg = 'Init with Constructor',
    EX Function(dynamic e, StackTrace s)? onCatch,
  }) : super(state: state, msg: msg, onCatch: onCatch);

  /// 处理前置触发条件, 防抖节流等
  /// 可选条件参数最多使用1个, 如果使用多个,则只有首个非空参数逻辑生效
  /// 如果不适用任何参数,则默认通过
  @protected
  T? reqWrapper<T>(
    T? Function() onAccess, {
    List<SidecarState>? accContain, // state 必须包含在 list 中
    List<SidecarState>? rejContain, // state 不能出现在 list 中
    bool Function()? accCustom, // 返回true即通过
    T? Function()? onReject,
  }) {
    // 默认通过
    bool accessed = true;

    if (accContain != null) {
      accessed = accContain.contains(state);
    } else if (rejContain != null) {
      accessed = !rejContain.contains(state);
    } else if (accCustom != null) {
      accessed = accCustom();
    }

    if (accessed) {
      return onAccess.call();
    } else {
      log("#[$runtimeType]::reqWrapper#已拒绝请求#状态[$state],[$msg]");
      return onReject?.call();
    }
  }

  /// 0.3 配置 `setXxx`方法
  /// set ----------------------------------------------------------------------
  T? setUninitialized<T>([String m = "未初始化", T Function()? before]) =>
      setState(SidecarState.uninitialized, m, before: before, traceLine: 2);

  T? setInitializing<T>([String m = "初始化...", T Function()? before]) =>
      setState(SidecarState.initializing, m, before: before, traceLine: 2);

  T? setInitialized<T>([String m = "初始化完成", T Function()? before]) =>
      setState(SidecarState.initialized, m, before: before, traceLine: 2);

  /// 0.4 配置 `actXxx`方法
  /// act ----------------------------------------------------------------------

  /// 状态设为 正在初始化
  /// onInitializing 函数内应当执行`耗时的初始化代码`
  Future<EX?> actInitializing({
    String m = "初始化...",
    Function()? onInitializing,
  }) =>
      actWrapper(() async {
        setInitializing(m);
        // 逻辑执行完毕后,应当调用 setXxx方法
        await onInitializing?.call() ?? await this.onInitializing();
      });

  /// 完成后需要手动调用 [setInitialized]
  @protected
  onInitializing();

  /// == deprecated ==
  @Deprecated('SidecarLoggerMx.setLogger')
  static get setLogger => SidecarLoggerMx.setLogger;
}
