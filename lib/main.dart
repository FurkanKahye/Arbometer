import 'package:flutter/material.dart';
import 'measurement_page.dart';

void main() {
  runApp(const TreeMeasurementApp());
}

class TreeMeasurementApp extends StatelessWidget {
  const TreeMeasurementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tree Height Measurer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const MeasurementPage(),
    );
  }
}