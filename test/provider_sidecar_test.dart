import 'package:flutter_test/flutter_test.dart';

import 'package:provider_sidecar/provider_sidecar.dart';

class BaseException {
  final String msg; // 直接向用户展示
  final String debugInfo; // 用于问题反馈，帮助定位BUG的信息，可以用stacktrace填充
  BaseException(this.msg, {this.debugInfo = ''});

  @override
  String toString({int maxInfoLen = 100}) =>
      'BaseException{msg: $msg, debugInfo: ${(debugInfo.length > maxInfoLen) ? '${debugInfo.substring(0, maxInfoLen)}...' : debugInfo}}';
}

abstract class MySidecar extends ProviderSidecar<BaseException> {}

class DeviceNicknameProvider extends ProviderSidecar {
  setStart() => reqWrapper(
        () => setInitialized("正在启动.."), // setXxx的简单业务逻辑
        accContain: [SidecarState.initialized], // 通过条件
        onReject: () => throw "尚未完成初始化, 当前状态[$state]",
      );

  @override
  onInitializing() async {
    try {
      // ... logic
      setInitialized();
    } catch (e) {
      // if (...) setUninitialized();
      rethrow;
    }
  }
}

void main() {
  test('set logger', () {
    // print log info
    ProviderSidecar.setLogger((message, [error, stackTrace]) => print(message));

    final provider = DeviceNicknameProvider();

    provider.actInitializing();
  });
}
