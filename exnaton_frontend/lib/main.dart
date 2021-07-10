import 'package:exnaton_frontend/ui/time_series_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exnaton measurements',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TimeSeriesScreen(),
    );
  }
}
