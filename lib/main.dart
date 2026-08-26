import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'widgets/connectivity_banner.dart';

void main() {
  // No storage bootstrap needed: the store lives behind SharedStoreProvider,
  // which Android brings up with the process.
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
