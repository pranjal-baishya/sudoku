import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/sudoku_screen.dart';
import 'providers/sudoku_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/theme_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hide status bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {'/': (context) => SplashScreen()},
            onGenerateRoute: (settings) {
              if (settings.name == '/home') {
                return PageRouteBuilder(
                  settings: settings,
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          SudokuScreen(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    var tween = Tween(
                      begin: 0.0,
                      end: 1.0,
                    ).chain(CurveTween(curve: Curves.easeInOut));

                    return FadeTransition(
                      opacity: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: Duration(milliseconds: 500),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
