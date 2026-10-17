import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final p = await SharedPreferences.getInstance();
  runApp(ForgeXApp(name: p.getString('name')));
}

class ForgeXApp extends StatelessWidget {
  final String? name;
  const ForgeXApp({super.key, this.name});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ForgeX',
        debugShowCheckedModeBanner: false,
        theme: FX.theme(),
        home: name == null ? const Onboarding() : Shell(name: name!),
      );
}
