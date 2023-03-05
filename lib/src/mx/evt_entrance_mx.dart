part of 'mx.dart';

///
/// Evt入口包装
mixin EvtEntranceMx<EVT, S> on BaseSidecar<S> {
  late final PublishSubject<EVT> _subject = PublishSubject<EVT>()
    ..stream.listen(
      onEvent,
      onError: onError,
    );

  // /// 覆写 [traceLine] 便于定位到[actEntrance]
  // /// 一般在 [onEvent]内部调用
  // @override
  // setState<T>(
  //   S? state,
  //   String m, {
  //   T? Function()? before,
  //   int traceLine = 2,
  // }) =>
  //     super.setState<T>(
  //       state,
  //       m,
  //       before: before,
  //       traceLine: traceLine,
  //     );

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
