import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ChangeNotifierProxyProvider<T, R extends ChangeNotifier?>
    extends ListenableProxyProvider<T, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider({
    Key? key,
    required Create<R> create,
    required ProxyProviderBuilder<T, R> update,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          update: update,
          dispose: _dispose,
          lazy: lazy,
          builder: builder,
          child: child,
        );

  ChangeNotifierProxyProvider.value({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder<T, R> update,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          update: update,
          lazy: lazy,
          builder: builder,
          child: child,
        );

  static void _dispose(BuildContext context, ChangeNotifier? notifier) =>
      notifier?.dispose();
}
