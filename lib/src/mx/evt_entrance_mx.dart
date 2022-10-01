part of 'mx.dart';

///
/// Evt入口包装
mixin EvtEntranceMx<EVT>{
  final StreamController<EVT> _evtCtrl = StreamController<EVT>.broadcast();

  void evtEntrance(EVT evt) => _evtCtrl.add(evt);

  Stream<EVT> get events => _evtCtrl.stream;
}
