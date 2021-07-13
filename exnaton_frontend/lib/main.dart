import 'package:exnaton_frontend/ui/time_series_screen.dart';
import 'package:flutter/material.dart';
// front end main function running MyApp()
void main() {
  runApp(MyApp());
}
// Calling TimeSeriesScreen() with some additional settings
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
