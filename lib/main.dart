import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/streaming_controller.dart';
import 'views/theme/app_theme.dart';
import 'views/screens/home_shell_screen.dart';
import 'views/screens/lock_screen.dart';

/// ============================================================================
/// [PUNTO DE ENTRADA] JG COMPANY S.A.S
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const JGCompanyApp());
}

class JGCompanyApp extends StatelessWidget {
  const JGCompanyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JG COMPANY S.A.S',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AppRoot(),
    );
  }
}

/// ============================================================================
/// [WIDGET] AppRoot — Decide si mostrar LockScreen o la app principal
/// ============================================================================
class AppRoot extends StatefulWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final StreamingController _streamingController;
  bool _isUnlocked = false;
  bool _checkingBiometric = true;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _streamingController = StreamingController();
    _streamingController.init();
    _checkBiometric();
  }

  @override
  void dispose() {
    _streamingController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final enabled = await BiometricService.isBiometricEnabled();
    final available = await BiometricService.isAvailable();

    setState(() {
      _biometricEnabled = enabled && available;
      // Si no hay biometría habilitada, desbloquear directo
      _isUnlocked = !_biometricEnabled;
      _checkingBiometric = false;
    });
  }

  void _onUnlocked() {
    setState(() => _isUnlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    // Mientras verifica la configuración
    if (_checkingBiometric) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.netflixRed, strokeWidth: 2),
        ),
      );
    }

    // Si biometría está activada y no ha desbloqueado → LockScreen
    if (_biometricEnabled && !_isUnlocked) {
      return LockScreen(onUnlocked: _onUnlocked);
    }

    // App principal
    return HomeShellScreen(streamingController: _streamingController);
  }
}
