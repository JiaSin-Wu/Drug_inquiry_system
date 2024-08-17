import 'my_home_page.dart';
import 'package:flutter/material.dart';

  void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Drug Info App',
      home: MyHomePage(title: "藥物查詢系統")
    );
  }
}


