import 'package:provider_sidecar/provider_sidecar_ex.dart';

///
/// since v1.5.x
/// 移除方法调用，完全改为事件驱动
abstract class SidecarProvider<EVT, STATE> extends BaseSidecar<STATE>
    with EvtEntranceMx<EVT, STATE> {
  SidecarProvider({required super.state});

  // @override
  // FutureOr<void> onEvent(evt) {
  //   // do some logic ...
  //   // setState( ... )     // change state
  //   // add( ... )          // add another event
  // }
}
