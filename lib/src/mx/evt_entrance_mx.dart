part of 'mx.dart';

///
/// Evt入口包装
mixin EvtEntranceMx<EVT> {
  late final StreamController<EVT> _evtCtrl = StreamController<EVT>.broadcast()
    ..stream.listen(onEvent);

  void evtEntrance(EVT evt) => _evtCtrl.add(evt);

  Stream<EVT> get events => _evtCtrl.stream;

  @mustCallSuper
  void onEvent(EVT evt) {}
}
