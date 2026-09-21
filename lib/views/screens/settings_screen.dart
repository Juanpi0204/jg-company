import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/streaming_controller.dart';
import '../../models/storage_service.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA / PANTALLA] SettingsScreen
/// ============================================================================
/// Pantalla de Gestión de Módulos del Ecosistema JG COMPANY S.A.S y Base de Datos:
/// 1. Módulos disponibles y en desarrollo:
///    - Pantallas Streaming (Activo)
///    - Mantenimiento Moto & Aceite (Kilometraje y cálculo de próximo cambio)
///    - Deudas y Préstamos
/// 2. Opciones de Respaldo de Base de Datos:
///    - Exportar copia de seguridad en JSON al portapapeles
///    - Importar copia de seguridad
/// ============================================================================
class SettingsScreen extends StatefulWidget {
  final StreamingController controller;

  const SettingsScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _faceIdActivo = true;

  // Estado para la simulación inicial del cálculo de la moto
  double _kmActualMoto = 12500;
  double _ultimoCambioKm = 10000;
  final double _intervaloCambio = 3000;

  double get _proximoCambioKm => _ultimoCambioKm + _intervaloCambio;
  double get _kmRestantes => _proximoCambioKm - _kmActualMoto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MÓDULOS DE JG COMPANY S.A.S',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            // 1. Módulo Streaming (Activo)
            _buildModuleCard(
              title: 'Cuentas & Pantallas Streaming',
              subtitle: 'Gestión de clientes, credenciales y ganancias',
              icon: Icons.tv_rounded,
              color: AppTheme.netflixRed,
              statusText: 'ACTIVO',
              statusColor: AppTheme.successGreen,
            ),

            const SizedBox(height: 12),

            // 2. Módulo Moto & Cambio de Aceite (Vista Previa Integrada)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.warningAmber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.two_wheeler_rounded, color: AppTheme.warningAmber, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Control de Moto & Aceite',
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'FASE 2',
                          style: TextStyle(color: AppTheme.warningAmber, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Cálculo en vivo de próximo cambio:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // Barra de Estado de Kilometraje
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Km Actual: ${_kmActualMoto.toStringAsFixed(0)} km', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Próximo: ${_proximoCambioKm.toStringAsFixed(0)} km', style: const TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ((_kmActualMoto - _ultimoCambioKm) / _intervaloCambio).clamp(0.0, 1.0),
                            backgroundColor: AppTheme.cardElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.warningAmber),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Te faltan ${_kmRestantes.toStringAsFixed(0)} km para el próximo cambio de aceite',
                          style: TextStyle(
                            color: _kmRestantes <= 500 ? AppTheme.netflixRed : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Módulo Deudas y Préstamos
            _buildModuleCard(
              title: 'Deudas y Préstamos',
              subtitle: 'Control de dinero prestado, intereses y cuotas',
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.infoBlue,
              statusText: 'PRÓXIMAMENTE',
              statusColor: AppTheme.textMuted,
            ),

            const SizedBox(height: 24),

            // Sección de Seguridad & Face ID
            const Text(
              'SEGURIDAD & BIOMETRÍA (iOS)',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.purpleAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.face_rounded, color: AppTheme.purpleAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Face ID / Touch ID',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Bloqueo biométrico al abrir la app',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _faceIdActivo,
                        activeColor: AppTheme.netflixRed,
                        onChanged: (val) {
                          setState(() => _faceIdActivo = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? '¡Face ID habilitado para iPhone!' : 'Face ID desactivado'),
                              backgroundColor: AppTheme.netflixRed,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppTheme.borderSubtle),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.netflixRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.dark_mode_rounded, color: AppTheme.netflixRed, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modo Oscuro OLED',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Estilo Netflix Obsidiana activado',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('ACTIVO', style: TextStyle(color: AppTheme.successGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Base de Datos y Respaldo
            const Text(
              'BASE DE DATOS Y RESPALDO',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cloud_download_rounded, color: AppTheme.infoBlue, size: 20),
                    ),
                    title: const Text('Exportar Respaldo JSON', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Copia un respaldo de todas tus cuentas para no perder datos', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    onTap: () async {
                      final backup = await StorageService.exportBackup(widget.controller.accounts);
                      await Clipboard.setData(ClipboardData(text: backup));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('¡Respaldo JSON copiado al portapapeles!'),
                            backgroundColor: AppTheme.netflixRed,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
