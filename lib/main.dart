import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/pickup/providers/pickup_provider.dart';
import 'features/collector/providers/collector_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/collector/screens/collector_dashboard_screen.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PickupProvider()),
        ChangeNotifierProvider(create: (_) => CollectorProvider()),
      ],
      child: MaterialApp(
        title: 'EcoTracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const AuthChecker(),
      ),
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    print('[AUTH CHECKER] Starting auth check...');
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check auth status
    await authProvider.checkAuthStatus();
    
    if (!mounted) return;
    
    print('[AUTH CHECKER] Is authenticated: ${authProvider.isAuthenticated}');
    
    if (authProvider.isAuthenticated && authProvider.user != null) {
      final user = authProvider.user!;
      final role = user.role.toLowerCase().trim();
      
      print('[AUTH CHECKER] User: ${user.name}');
      print('[AUTH CHECKER] Email: ${user.email}');
      print('[AUTH CHECKER] Role: "$role"');
      
      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      // Route based on role
      if (role == 'collector') {
        print('[AUTH CHECKER] ✓ Navigating to COLLECTOR dashboard');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CollectorDashboardScreen(),
          ),
        );
      } else if (role == 'user') {
        print('[AUTH CHECKER] ✓ Navigating to USER dashboard');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      } else {
        print('[AUTH CHECKER] ⚠ Unknown role: $role - defaulting to USER dashboard');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    } else {
      print('[AUTH CHECKER] Not authenticated - showing login');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}