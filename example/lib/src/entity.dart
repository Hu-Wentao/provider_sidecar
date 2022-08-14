class Town {
  final String id;
  final String name;
  final List<String> families;

  Town(this.id, this.name, this.families);
}

class Family {
  final String id;
  final String name;
  final List<String> persons;

  Family(this.id, this.name, this.persons);
}

class Person {
  final String id;
  final String name;
  final int age;

  Person(this.id, this.name, this.age);
}
