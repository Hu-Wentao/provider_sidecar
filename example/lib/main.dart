import 'package:example/src/fake.dart';
import 'package:example/src/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_sidecar/provider_sidecar.dart';

import 'src/entity.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SidecarLoggerMx.setLogger((m, [e, s]) {
    print("日志消息($m), err($e), trace(\n$s)");
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Flutter Demo',
        home: MyHomePage(title: 'Town List Page'),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Town> towns = [];

  @override
  initState() {
    super.initState();
    towns = fakeData.fakeTowns;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: SingleChildScrollView(
          child: Column(
            children: towns
                .map((e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.id),
                      trailing: Text("(${e.families.length} family)"),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) {
                          return TownPage(town: e);
                        }));
                      },
                    ))
                .toList(),
          ),
        ),
      );
}

class TownPage extends StatelessWidget {
  final Town town;

  const TownPage({Key? key, required this.town}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text("Town# ${town.name}")),
        body: ChangeNotifierProvider<TownModel>(
            create: (c) => TownModel(town)..actInitSubscription(),
            child: Consumer<TownModel>(
              builder: (c, m, _) => SingleChildScrollView(
                child: Column(
                  children: m.familyModels
                      .map((fm) => ListTile(
                            title: Text(fm.data.name),
                            subtitle: Text(fm.data.id),
                            trailing:
                                Text("(${fm.data.persons.length} person)"),
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (c) {
                                // m.actInitSubscription();
                                return ChangeNotifierProvider<
                                    FamilyModel>.value(
                                  value: fm..actInitSubscription(),
                                  child: FamilyPage(family: fm.data),
                                );
                              }));
                            },
                          ))
                      .toList(),
                ),
              ),
            )),
      );
}

class FamilyPage extends StatelessWidget {
  final Family family;

  const FamilyPage({Key? key, required this.family}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text("Family# ${family.name}")),
        body: Consumer<FamilyModel>(
          builder: (c, m, _) => SingleChildScrollView(
            child: Column(
              children: m.personModels
                  .map((e) => ListTile(
                        title: Text(e.data.name),
                        subtitle: Text(e.data.id),
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (c) {
                            return ChangeNotifierProvider<PersonModel>.value(
                                value: e, child: PersonPage(person: e.data));
                          }));
                        },
                      ))
                  .toList(),
            ),
          ),
        ),
      );
}

class PersonPage extends StatelessWidget {
  final Person person;

  const PersonPage({Key? key, required this.person}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text("Person# ${person.name}")),
        body: Consumer<PersonModel>(
          builder: (c, m, _) => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ListTile(leading: const Text("Id"), title: Text(" ${m.data.id}")),
              ListTile(
                  leading: const Text("Name"), title: Text(" ${m.data.name}")),
              ListTile(
                  leading: const Text("Age"), title: Text(" ${m.data.age}")),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Text("do sth"),
          onPressed: () => context.read<PersonModel>().actDoSthError(),
        ),
      );
}
