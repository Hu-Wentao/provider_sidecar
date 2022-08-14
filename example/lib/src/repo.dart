import 'package:example/src/entity.dart';
import 'package:example/src/fake.dart';

final fakeTownRepo = TownRepo();
final fakeFamilyRepo = FamilyRepo();
final fakePersonRepo = PersonRepo();

class TownRepo {
  Stream<Town> findAll() => Stream.fromIterable(fakeData.fakeTowns);

  Future<Town> findById(String id) async =>
      findAll().firstWhere((element) => element.id == id);
}

class FamilyRepo {
  Stream<Family> findAll() => Stream.fromIterable(fakeData.fakeFamilies);

  Stream<Family> findAllBy(String townId) async* {
    final town = await fakeTownRepo.findById(townId);
    final all = await findAll().toList();
    yield* Stream.fromIterable(
        town.families.map((e) => all.firstWhere((element) => element.id == e)));
  }

  Future<Family> findById(String id) async =>
      fakeData.fakeFamilies.firstWhere((element) => element.id == id);
}

class PersonRepo {
  Stream<Person> findAll() => Stream.fromIterable(fakeData.fakePersons);

  Stream<Person> findAllBy(String familyId) async* {
    final family = await fakeFamilyRepo.findById(familyId);
    final all = await findAll().toList();
    yield* Stream.fromIterable(family.persons
        .map((e) => all.firstWhere((element) => element.id == e)));
  }

  Future<Person> findById(String id) async =>
      fakeData.fakePersons.firstWhere((element) => element.id == id);
}
