import 'package:flutter_test/flutter_test.dart';
import 'package:provider_sidecar/src/utils.dart';

main() {
  const src = """
#0      ModelSidecar.reqWrapper (package:provider_sidecar/src/model_sidecar.dart:90:66)
#1      AppStateModel.actUserAutoLogged.<anonymous closure> (package:mind_base/src/app/application/model/app_state_model.dart:119:30)
#2      Sidecar.actWrapper (package:provider_sidecar/src/sidecar.dart:143:21)
""";
  const target =
      "AppStateModel.actUserAutoLogged.<anonymous closure> (package:mind_base/src/app/application/model/app_state_model.dart:119:30)";

  test("selectLineAt", () {
    expect(selectLineAt(src, 1), target);
  });

  test("parentLineBy", () {
    const trace = src;
    final index = findLineIndexBy(trace, '.reqWrapper');
    final r = index == null ? null : selectLineAt(trace, index + 1);
    expect(r, target);
  });

  test("onlyStack", () {
    const traceLine =
        "StateChangeMx.actInitSubscription.<anonymous closure>.<anonymous closure> (package:provider_sidecar/src/model_sidecar.dart:182:13)";
    final r3 = onlyStack(traceLine);
    expect(r3, 'package:provider_sidecar/src/model_sidecar.dart:182:13');
  });
}
