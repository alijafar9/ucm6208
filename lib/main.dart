import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ui/simple_call_screen.dart';
import 'bindings/call_binding.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UCM6208',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialBinding: CallBinding(),
      home: const SimpleCallScreen(),
      // You can add routes here if needed
    );
  }
}
