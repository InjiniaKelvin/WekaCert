import 'package:flutter/material.dart';

import 'screens/document_detail_screen.dart';
import 'screens/document_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/upload_screen.dart';

void main() {
  runApp(const WekaCertApp());
}

class WekaCertApp extends StatelessWidget {
  const WekaCertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WekaCert',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        DocumentListScreen.routeName: (context) => const DocumentListScreen(),
        DocumentDetailScreen.routeName: (context) => const DocumentDetailScreen(),
        UploadScreen.routeName: (context) => const UploadScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
    );
  }
}
