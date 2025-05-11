import 'package:flutter/material.dart';
import 'package:flutter_formatter_framework_example/formatters/mask_formatter_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formatter Framework Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: const MaskFormatterPage(),
    );
  }
}
