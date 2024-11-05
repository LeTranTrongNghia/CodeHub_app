import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localizations
import 'package:intl/intl.dart'; // Import intl
import 'package:forui/forui.dart';
import 'firebase/firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'package:provider/provider.dart';
import 'controllers/language_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageController(),
      child: const Application(),
    ),
  );
}

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Set the design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          builder: (context, child) => FTheme(
            data: FThemes.zinc.light,
            child: child!,
          ),
          home: const AuthScreen(),
          debugShowCheckedModeBanner: false,

          // Add localization support
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Define supported locales
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('vi', ''), // Vietnamese
          ],

          // Optionally: Set initial locale based on user preferences or system settings
          locale: Locale('vi'), // Set default locale to Vietnamese (optional)
        );
      },
    );
  }
}
