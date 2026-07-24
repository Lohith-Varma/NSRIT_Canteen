import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';

import '../../providers/auth_provider.dart';
import '../main_layout.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool autoNavigate;

  const SplashScreen({super.key, this.autoNavigate = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('[startup] SplashScreen.initState() entered');
    if (widget.autoNavigate) {
      debugPrint('[startup] SplashScreen starting auth navigation check');
      _checkAuthAndNavigate();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    debugPrint('[startup] SplashScreen waiting before navigation');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    debugPrint('[startup] SplashScreen reading AuthProvider');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint(
      '[startup] SplashScreen auth state: '
      'isLoading=${authProvider.isLoading}, '
      'isAuthenticated=${authProvider.isAuthenticated}',
    );
    if (authProvider.isAuthenticated) {
      debugPrint('[startup] SplashScreen navigating to MainLayout');
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainLayout()));
    } else {
      debugPrint('[startup] SplashScreen navigating to LoginScreen');
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[startup] SplashScreen.build() entered');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'NSRIT CANTEEN',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'College Inventory Management System',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            const SpinKitCubeGrid(color: Colors.white, size: 36),
          ],
        ),
      ),
    );
  }
}
