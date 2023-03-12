part of 'mx.dart';

///
/// Evt入口包装
@Deprecated('SidecarEvtMx')
mixin EvtEntranceMx<EVT, S> on BaseSidecar<S> {
  late final PublishSubject<EVT> _subject = PublishSubject<EVT>()
    ..stream.listen(
      onEvent,
      onError: onError,
    );

  ///
  void add(EVT? evt) => (evt == null) ? null : _subject.add(evt);

  Stream<EVT> get events => _subject.stream;

  @mustCallSuper
  FutureOr<void> onEvent(EVT evt);

  @mustCallSuper
  onError(e, s) {
    log('actWrapper.catch# [${e.runtimeType}] ${StackTrace.current} \n$e,\n$s');
  }
}

mixin SidecarEvtMx<EVT> on SidecarLoggerMx {
  late final PublishSubject<EVT> _subject = PublishSubject<EVT>()
    ..stream.listen(
          (e) {
        log('onEvent# $e');
        onEvent(e);
      },
      onError: onError,
    );

  ///
  void add(EVT? evt) => (evt == null) ? null : _subject.add(evt);

  Stream<EVT> get events => _subject.stream;

  @mustCallSuper
  FutureOr<void> onEvent(EVT evt);

  @mustCallSuper
  onError(e, s) {
    lgShot(
        'actWrapper.catch# [${e.runtimeType}] ${StackTrace.current} \n$e,\n$s');
  }
}
