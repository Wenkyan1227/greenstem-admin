import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/create_job_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/mechanics_screen.dart';
import 'screens/forgot_password.dart';
import 'package:greenstem_admin/services/notification_service.dart';

// import 'services/vehicle_service.dart';
// import 'services/service_task_catalog_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize default vehicle data
  // final vehicleService = VehicleService();
  // await vehicleService.addVehicleBrands();

  // Initialize default service data
  // final serviceTaskService = ServiceTaskCatalogService();
  // await serviceTaskService.addDummyServiceTasks();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenStem Admin',
      theme: ThemeData(
        primaryColor: Color(0xFF29A87A),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF29A87A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF29A87A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF29A87A),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF29A87A),
          primary: Color(0xFF29A87A),
          background: Colors.white,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const MainNavigation(),
        '/create-job': (context) => const CreateJobScreen(),
        '/jobs': (context) => const JobsScreen(),
        '/mechanics': (context) => const MechanicsScreen(),
      },
    );
  }
}
