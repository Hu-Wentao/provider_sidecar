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
  StreamSubscription? _onInitStateMxSub;

  @override
  void initState() {
    Future.microtask(() {
      final msgr = ScaffoldMessenger.of(context);
      final a = context.read<A>();
      final b = context.read<B>();
      _onInitStateMxSub = onInitState(msgr, a, b);
    });
    super.initState();
  }

  StreamSubscription? onInitState(ScaffoldMessengerState msgr, A a, B b);

  @override
  dispose() {
    _onInitStateMxSub?.cancel();
    super.dispose();
  }
}

mixin OnInitStateMx3<PAGE extends StatefulWidget, A, B, C> on State<PAGE> {
  StreamSubscription? _onInitStateMxSub;

  @override
  void initState() {
    Future.microtask(() {
      final msgr = ScaffoldMessenger.of(context);
      final a = context.read<A>();
      final b = context.read<B>();
      final c = context.read<C>();
      _onInitStateMxSub = onInitState(msgr, a, b, c);
    });
    super.initState();
  }

  StreamSubscription? onInitState(ScaffoldMessengerState msgr, A a, B b, C c);

  @override
  dispose() {
    _onInitStateMxSub?.cancel();
    super.dispose();
  }
}
