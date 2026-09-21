import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [SERVICIO] BiometricService — Face ID / Touch ID / Huella
/// ============================================================================
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Usa Face ID o tu huella para acceder a JG Company',
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBiometricEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('biometric_enabled') ?? false;
  }

  static Future<void> setBiometricEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('biometric_enabled', value);
  }
}

/// ============================================================================
/// [VISTA] LockScreen — Pantalla de bloqueo biométrico
/// ============================================================================
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({Key? key, required this.onUnlocked}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool _authenticating = false;
  bool _failed = false;
  String _mensaje = 'Toca el ícono para autenticarte';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // Intenta autenticar automáticamente al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) => _intentarAuth());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _intentarAuth() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _failed = false;
      _mensaje = 'Verificando identidad...';
    });

    final ok = await BiometricService.authenticate();

    if (!mounted) return;

    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _authenticating = false;
        _failed = true;
        _mensaje = 'No se pudo verificar.\nToca para intentar de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── LOGO JG ───────────────────────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppTheme.redGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.redGlow,
                  ),
                  child: const Center(
                    child: Text(
                      'JG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'JG COMPANY S.A.S',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Acceso protegido',
                  style: TextStyle(color: Color(0xFF666677), fontSize: 13),
                ),

                const SizedBox(height: 56),

                // ── BOTÓN BIOMÉTRICO ANIMADO ───────────────────────────────
                GestureDetector(
                  onTap: _authenticating ? null : _intentarAuth,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _authenticating ? _pulseAnim.value : 1.0,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_failed ? AppTheme.netflixRed : const Color(0xFF7C83FD))
                            .withOpacity(0.1),
                        border: Border.all(
                          color: (_failed ? AppTheme.netflixRed : const Color(0xFF7C83FD))
                              .withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_failed ? AppTheme.netflixRed : const Color(0xFF7C83FD))
                                .withOpacity(0.22),
                            blurRadius: 26,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _failed
                            ? Icons.error_outline_rounded
                            : Icons.face_retouching_natural_rounded,
                        size: 54,
                        color: _failed
                            ? AppTheme.netflixRed
                            : const Color(0xFF7C83FD),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── MENSAJE DE ESTADO ──────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _mensaje,
                    key: ValueKey(_mensaje),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _failed
                          ? AppTheme.netflixRed
                          : const Color(0xFF888899),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                if (_failed)
                  TextButton.icon(
                    onPressed: _intentarAuth,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Intentar de nuevo'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C83FD),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
