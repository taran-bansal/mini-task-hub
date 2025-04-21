import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/theme.dart';
import 'screens/splash_screen.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'auth/auth_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'services/task_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dwfxrpgkczxzrwvhfnrf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3ZnhycGdrY3p4enJ3dmhmbnJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNjMzOTMsImV4cCI6MjA2MDczOTM5M30.ynXPJh0eQqXWzN9njuuGTW_ispgfM1OkhJTqCXAktVc',
  );

  Get.put(AuthService());
  Get.put(TaskService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DayTask',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(
          name: '/main',
          page: () => const DashboardScreen(),
          middlewares: [AuthMiddleware()],
        ),
      ],
    );
  }
}

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    return authService.currentUser.value == null
        ? const RouteSettings(name: '/login')
        : null;
  }
}
