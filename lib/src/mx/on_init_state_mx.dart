part of 'mx.dart';

mixin OnInitStateMx<PAGE extends StatefulWidget, A> on State<PAGE> {
  StreamSubscription? _onInitStateMxSub;

  @override
  void initState() {
    Future.microtask(() {
      final msgr = ScaffoldMessenger.of(context);
      final a = context.read<A>();
      _onInitStateMxSub = onInitState(msgr, a);
    });
    super.initState();
  }

  StreamSubscription? onInitState(ScaffoldMessengerState msgr, A a);

  @override
  dispose() {
    _onInitStateMxSub?.cancel();
    super.dispose();
  }
}

mixin OnInitStateMx2<PAGE extends StatefulWidget, A, B> on State<PAGE> {
  @override
  void initState() {
    Future.microtask(() {
      final msgr = ScaffoldMessenger.of(context);
      final a = context.read<A>();
      final b = context.read<B>();
      onInitState(msgr, a, b);
    });
    super.initState();
  }

  onInitState(ScaffoldMessengerState msgr, A a, B b);
}

mixin OnInitStateMx3<PAGE extends StatefulWidget, A, B, C> on State<PAGE> {
  @override
  void initState() {
    Future.microtask(() {
      final msgr = ScaffoldMessenger.of(context);
      final a = context.read<A>();
      final b = context.read<B>();
      final c = context.read<C>();
      onInitState(msgr, a, b, c);
    });
    super.initState();
  }

  onInitState(ScaffoldMessengerState msgr, A a, B b, C c);
}
