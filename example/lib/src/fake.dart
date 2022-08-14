import 'dart:math';

import 'package:example/src/entity.dart';
import 'package:faker/faker.dart' as fk;

final fakeData = FakeDataSource();

class FakeDataSource {
  final _rd = Random();
  List<Town> fakeTowns = [];

  List<Family> fakeFamilies = [];
  List<Person> fakePersons = [];

  FakeDataSource() {
    _genTowns();
  }

  _genTowns() {
    fakeTowns.addAll(List.generate(
      2 + _rd.nextInt(8),
      (townId) => Town(
        "$townId",
        fk.faker.address.city(),
        _genFamilies(townId),
      ),
    ));
    return fakeTowns.map((e) => e.id).toList();
  }

  List<String> _genFamilies(int townId) {
    final f = List.generate(
      10 + _rd.nextInt(40),
      (familyId) => Family(
        "$townId-$familyId",
        fk.faker.job.title(),
        _genPersons(townId, familyId),
      ),
    );
    fakeFamilies.addAll(f);
    return f.map((e) => e.id).toList();
  }

  List<String> _genPersons(int townId, int familyId) {
    final p = List.generate(
        1 + _rd.nextInt(5),
        (index) => Person("$townId-$familyId-$index", fk.faker.person.name(),
            15 + _rd.nextInt(45)));
    fakePersons.addAll(p);
    return p.map((e) => e.id).toList();
  }
}
