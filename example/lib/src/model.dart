import 'package:example/src/entity.dart';
import 'package:example/src/repo.dart';
import 'package:provider_sidecar/provider_sidecar.dart';

_onCatchError(e, s) {
  print("_onCatchError # $e \n$s");
}

///
/// Model直接持有子状态，如[familyModels],
/// 以便于控制子状态的生命周期，数据刷新等
class TownModel extends ModelSidecar<Town, dynamic>
    with StateChangeMx<Town, dynamic> {
  TownModel(Town data)
      : familyModels = [],
        super(data, _onCatchError);

  /// 子状态
  /// 注意，子状态不一定要继承[ModelSidecar]
  List<FamilyModel> familyModels;

  _newFamilyModel(Family data) {
    familyModels.add(FamilyModel(data)
      // 在这里配置init，则立即为 FamilyModel充血
      ..actInitSubscription());
    setDone('新增Family [$data]');
  }

  @override
  Future<bool?> onFetch({bool isActive = false}) async {
    data.families
        .map((familyId) async =>
            _newFamilyModel(await fakeFamilyRepo.findById(familyId)))
        // 注意，Iterable必须toList才会执行map等逻辑
        .toList();
    return true;
  }

  @override
  Future<bool?> onReset() async {
    familyModels.clear();
    return true;
  }
}

class FamilyModel extends ModelSidecar<Family, dynamic>
    with StateChangeMx<Family, dynamic> {
  FamilyModel(Family data)
      : personModels = [],
        super(data, _onCatchError);

  // 子状态
  final List<PersonModel> personModels;

  _newPeronModel(Person data) {
    personModels.add(PersonModel(data));
    setDone('新增Person [$data]');
  }

  @override
  Future<bool?> onFetch({bool isActive = false}) async {
    data.persons
        .map((e) async => _newPeronModel(await fakePersonRepo.findById(e)))
        // 必须toList，否则逻辑不执行
        .toList();
    return true;
  }

  @override
  Future<bool?> onReset() async {
    personModels.clear();
    return true;
  }
}

/// 由于[PersonModel]目前没有子状态，
/// 所以无需混入[StateChangeMx]
/// 如果没有方法，可以直接使用[Person]，而无需新建[PersonModel]类
class PersonModel extends ModelSidecar<Person, dynamic> {
  PersonModel(Person data) : super(data, _onCatchError);

  // 返回值类型即 可空的抛出的异常类型，本例中，异常类型为dynamic，所以也返回dynamic
  Future<dynamic> actDoSthError() async => await actWrapper(() {
        throw "do sth error !";
      });
}
