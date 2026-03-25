import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/pickup/providers/pickup_provider.dart';
import 'features/pickup/screens/create_pickup_screen.dart';
import 'features/badge/providers/badge_provider.dart';
import 'features/badge/screens/badges_screen.dart';
import 'features/report/providers/report_provider.dart';
import 'features/feedback/screens/feedback_screen.dart';
import 'features/collector/providers/collector_provider.dart';
import 'features/collector/screens/collector_dashboard.dart';
import 'features/pickup/network/websocket_service.dart'; // tambah import ini

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcoTrackerApp());
}

class EcoTrackerApp extends StatelessWidget {
  const EcoTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => PickupProvider()),
    ChangeNotifierProvider(create: (_) => ReportProvider()),
    ChangeNotifierProvider(create: (_) => FeedbackProvider()),
    ChangeNotifierProvider(create: (_) => CollectorProvider()),
    ChangeNotifierProvider(create: (_) => BadgeProvider()),
    ChangeNotifierProvider(create: (_) => WebSocketService()), // tambah ini
  ],
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          final isCollector = auth.user?.isCollector ?? false;
          return MaterialApp(
            title: 'EcoTracker',
            debugShowCheckedModeBanner: false,
            theme: isCollector
                ? AppTheme.collectorTheme
                : AppTheme.userTheme,
            home: const SplashScreen(),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/home': (_) => const HomeScreen(),
              '/collector-home': (_) => const CollectorHomeScreen(),
              '/create-pickup': (_) => const CreatePickupScreen(),
              '/feedback': (_) => const FeedbackScreen(),
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.tryAutoLogin();

    if (!mounted) return;
    if (loggedIn) {
      if (auth.user?.isCollector == true) {
        Navigator.pushReplacementNamed(context, '/collector-home');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.eco_rounded,
                    size: 60, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'EcoTracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bersama kita jaga lingkungan 🌿',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}