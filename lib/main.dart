import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sudoku_provider.dart';
import 'screens/sudoku_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SudokuProvider(),
      child: MaterialApp(home: SudokuScreen()),
    );
  }
}
