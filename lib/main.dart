import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kafela/services/database_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/shared/auth_wrapper.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
      ],
      child: MaterialApp(
        title: 'Kafela',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white, // whole app background white
          primaryColor: Colors.green, // primary green
          fontFamily: 'Libertinus', // global font

          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              color: Colors.black, // text black
            ),
          ),

          elevatedButtonTheme: const ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor:
                  WidgetStatePropertyAll(Colors.green), // global button green
              foregroundColor:
                  WidgetStatePropertyAll(Colors.white), // button text white
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
