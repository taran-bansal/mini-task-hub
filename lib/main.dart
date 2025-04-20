import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/theme.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dwfxrpgkczxzrwvhfnrf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3ZnhycGdrY3p4enJ3dmhmbnJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNjMzOTMsImV4cCI6MjA2MDczOTM5M30.ynXPJh0eQqXWzN9njuuGTW_ispgfM1OkhJTqCXAktVc',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DayTask',
      theme: AppTheme.theme,
      initialRoute: Supabase.instance.client.auth.currentUser == null
          ? '/login'
          : '/dashboard',
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/signup',
          page: () => const SignupScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/dashboard',
          page: () => const DashboardScreen(),
          transition: Transition.fadeIn,
          middlewares: [
            RouteGuard(),
          ],
        ),
      ],
    );
  }
}

class RouteGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    return Supabase.instance.client.auth.currentUser == null
        ? const RouteSettings(name: '/login')
        : null;
  }
}
