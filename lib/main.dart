import 'package:flutter/material.dart';
import 'package:mmkv/mmkv.dart';

import 'screens/home_screen.dart';
import 'widgets/connectivity_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MMKV must finish initialization before any encode/decode calls occur.
  await MMKV.initialize();

  runApp(const FsdApp());
}

class FsdApp extends StatelessWidget {
  const FsdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ConnectivityBanner(child: child ?? const SizedBox.shrink());
      },
      home: const HomeScreen(),
    );
  }
}
