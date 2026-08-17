// ignore_for_file: slash_for_doc_comments
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'core/auth_service.dart';
import 'core/business_provider.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/shared/main_navigation_shell.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService()..tryAutoLogin(),
        ),
        ChangeNotifierProvider(
          create: (_) => BusinessProvider(),
        ),
      ],
      child: const Back2KasiApp(),
    ),
  );
}

/**
 * Main Application widget configuring routes, theme, and authentication state listener.
 */
class Back2KasiApp extends StatelessWidget {
  const Back2KasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return MaterialApp(
      title: 'Back2Kasi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      
      // Dynamic home screen routing depending on auth state
      home: authService.isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : authService.isAuthenticated
              ? const MainNavigationShell()
              : const LoginScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigationShell(),
      },
    );
  }
}
