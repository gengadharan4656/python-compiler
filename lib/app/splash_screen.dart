import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/platform/python_channel.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _initRuntime();
  }

  Future<void> _initRuntime() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _statusText = 'Loading Python runtime...');
    try {
      await PythonChannel.instance.initializePython();
      setState(() => _statusText = 'Ready!');
    } catch (_) {
      setState(() => _statusText = 'Ready');
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: AppTheme.accentBlue, borderRadius: BorderRadius.circular(24)),
                child: const Center(child: Text('Py', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 24),
              const Text('PyDroid', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('Python IDE for Android', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
              const SizedBox(height: 48),
              SizedBox(width: 32, height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue))),
              const SizedBox(height: 16),
              Text(_statusText, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
