import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sudoku_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/sudoku_screen.dart';
import 'utils/theme_config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SudokuProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Sudoku',
            theme: ThemeConfig.lightTheme,
            darkTheme: ThemeConfig.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: SudokuScreen(),
          );
        },
      ),
    );
  }
}
