part of 'mx.dart';

mixin OnInitStateMx<MODEL, PAGE extends StatefulWidget> on State<PAGE> {
  @override
  void initState() {
    Future.microtask(() {
      final msgr = ScaffoldMessenger.of(context);
      final model = context.read<MODEL>();
      onInitState(model, msgr);
    });
    super.initState();
  }

  onInitState(MODEL model, ScaffoldMessengerState msgr);
}
