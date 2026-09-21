import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/streaming_controller.dart';
import '../../controllers/reports_controller.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA / PANTALLA] MainMenuScreen
/// ============================================================================
/// Menú Principal y Panel de Control Central de JG COMPANY S.A.S.
/// Inspirado fielmente en la estructura del Excel del usuario:
/// - NETFLIX & STREAMING (Módulo activo completo)
/// - CONTROL DE MOTO & ACEITE (Kilometraje y recordatorio)
/// - DEUDAS Y PRÉSTAMOS
/// - ALCANCÍA META
/// - INVENTARIO
/// - FACTURAS
/// - PUNTACANA
/// - DISPONIBLES ALI / RECIBIDOS ALI
/// - CONTEO
/// ============================================================================
class MainMenuScreen extends StatefulWidget {
  final StreamingController streamingController;
  final VoidCallback onOpenStreaming;

  const MainMenuScreen({
    Key? key,
    required this.streamingController,
    required this.onOpenStreaming,
  }) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // Datos interactivos para la Moto
  double _kmActualMoto = 12500;
  final double _ultimoCambioKm = 10000;
  final double _intervaloCambio = 3000;

  double get _proximoCambioKm => _ultimoCambioKm + _intervaloCambio;
  double get _kmRestantes => _proximoCambioKm - _kmActualMoto;

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return AnimatedBuilder(
      animation: widget.streamingController,
      builder: (context, _) {
        final accounts = widget.streamingController.accounts;
        final gananciaTotal = ReportsController.gananciaNeta(accounts);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // 1. Barra de Encabezado Superior
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.redGradient,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: AppTheme.redGlow,
                                  ),
                                  child: const Text(
                                    'JG',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'JG COMPANY S.A.S',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'Base de Datos & Gestión',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.apple, size: 14, color: AppTheme.textSecondary),
                                  SizedBox(width: 4),
                                  Text(
                                    'iOS Pro',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Tarjeta Hero: Resumen Rápido de Ganancias
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E1E28), Color(0xFF131318)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderLight),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'GANANCIA TOTAL STREAMING',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${accounts.length} pantallas',
                                      style: const TextStyle(
                                        color: AppTheme.successGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatoMoneda.format(gananciaTotal),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'MÓDULOS DE LA EMPRESA',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Grid de Módulos (Exactos al Menú Principal del Excel)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                    children: [
                      // 1. NETFLIX & STREAMING (MÓDULO ACTIVO)
                      _buildMenuCard(
                        title: 'NETFLIX &\nSTREAMING',
                        subtitle: '${accounts.length} Clientes / Pantallas',
                        icon: Icons.tv_rounded,
                        accentColor: AppTheme.netflixRed,
                        badgeText: 'ACTIVO',
                        badgeColor: AppTheme.successGreen,
                        esDestacado: true,
                        onTap: widget.onOpenStreaming,
                      ),

                      // 2. CONTROL DE MOTO & ACEITE
                      _buildMenuCard(
                        title: 'MOTO &\nACEITE',
                        subtitle: '${_kmRestantes.toStringAsFixed(0)} km restantes',
                        icon: Icons.two_wheeler_rounded,
                        accentColor: AppTheme.warningAmber,
                        badgeText: 'ACTIVO',
                        badgeColor: AppTheme.warningAmber,
                        onTap: _mostrarModalMoto,
                      ),

                      // 3. DEUDAS Y PRÉSTAMOS
                      _buildMenuCard(
                        title: 'DEUDAS Y\nPRÉSTAMOS',
                        subtitle: 'Control de cobros',
                        icon: Icons.account_balance_wallet_rounded,
                        accentColor: AppTheme.infoBlue,
                        badgeText: 'PRÓXIMO',
                        badgeColor: AppTheme.infoBlue,
                        onTap: () => _mostrarAvisoModulo('Deudas y Préstamos'),
                      ),

                      // 4. ALCANCÍA META
                      _buildMenuCard(
                        title: 'ALCANCÍA\nMETA',
                        subtitle: 'Metas de Ahorro',
                        icon: Icons.savings_rounded,
                        accentColor: Colors.pinkAccent,
                        badgeText: 'PRÓXIMO',
                        badgeColor: Colors.pinkAccent,
                        onTap: () => _mostrarAvisoModulo('Alcancía Meta'),
                      ),

                      // 5. INVENTARIO
                      _buildMenuCard(
                        title: 'INVENTARIO\nGENERAL',
                        subtitle: 'Stock y Cuentas',
                        icon: Icons.inventory_2_rounded,
                        accentColor: Colors.tealAccent,
                        badgeText: 'PRÓXIMO',
                        badgeColor: Colors.tealAccent,
                        onTap: () => _mostrarAvisoModulo('Inventario'),
                      ),

                      // 6. FACTURAS
                      _buildMenuCard(
                        title: 'FACTURAS &\nRECIBOS',
                        subtitle: 'Historial de pagos',
                        icon: Icons.receipt_long_rounded,
                        accentColor: Colors.deepPurpleAccent,
                        badgeText: 'PRÓXIMO',
                        badgeColor: Colors.deepPurpleAccent,
                        onTap: () => _mostrarAvisoModulo('Facturas'),
                      ),

                      // 7. PUNTACANA
                      _buildMenuCard(
                        title: 'PUNTACANA\nPROVEEDOR',
                        subtitle: 'Cuentas y compras',
                        icon: Icons.beach_access_rounded,
                        accentColor: Colors.orangeAccent,
                        badgeText: 'PRÓXIMO',
                        badgeColor: Colors.orangeAccent,
                        onTap: () => _mostrarAvisoModulo('Puntacana'),
                      ),

                      // 8. DISPONIBLES / RECIBIDOS ALI
                      _buildMenuCard(
                        title: 'DISPONIBLES\nALI',
                        subtitle: 'Pantallas libres',
                        icon: Icons.swap_horiz_rounded,
                        accentColor: Colors.cyanAccent,
                        badgeText: 'PRÓXIMO',
                        badgeColor: Colors.cyanAccent,
                        onTap: () => _mostrarAvisoModulo('Disponibles Ali'),
                      ),

                      // 9. CONTEO
                      _buildMenuCard(
                        title: 'CONTEO &\nCIERRE',
                        subtitle: 'Balance de caja',
                        icon: Icons.calculate_rounded,
                        accentColor: Colors.lightGreenAccent,
                        badgeText: 'PRÓXIMO',
                        badgeColor: Colors.lightGreenAccent,
                        onTap: () => _mostrarAvisoModulo('Conteo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
    bool esDestacado = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: esDestacado ? const Color(0xFF1E1517) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: esDestacado ? AppTheme.netflixRed.withOpacity(0.5) : AppTheme.borderSubtle,
              width: esDestacado ? 1.5 : 1,
            ),
            boxShadow: esDestacado ? AppTheme.redGlow : AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fila Superior: Icono y Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              // Texto del Módulo
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalMoto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final restantes = _proximoCambioKm - _kmActualMoto;
          final progreso = ((_kmActualMoto - _ultimoCambioKm) / _intervaloCambio).clamp(0.0, 1.0);

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.two_wheeler_rounded, color: AppTheme.warningAmber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'CONTROL DE MOTO & ACEITE',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Km Actual: ${_kmActualMoto.toStringAsFixed(0)} km', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Próximo: ${_proximoCambioKm.toStringAsFixed(0)} km', style: const TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: AppTheme.cardElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              restantes <= 500 ? AppTheme.netflixRed : AppTheme.warningAmber,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          restantes > 0
                              ? 'Te faltan ${restantes.toStringAsFixed(0)} km para el próximo cambio'
                              : '¡ATENCIÓN! Cambio de aceite vencido por ${(-restantes).toStringAsFixed(0)} km',
                          style: TextStyle(
                            color: restantes <= 500 ? AppTheme.netflixRed : AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Actualizar Kilometraje de la Moto:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Slider(
                    value: _kmActualMoto,
                    min: 10000,
                    max: 14000,
                    divisions: 40,
                    activeColor: AppTheme.warningAmber,
                    inactiveColor: AppTheme.cardElevated,
                    label: '${_kmActualMoto.toStringAsFixed(0)} km',
                    onChanged: (val) {
                      setState(() => _kmActualMoto = val);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarAvisoModulo(String modulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Módulo "$modulo" listo para ser activado en la siguiente fase.'),
        backgroundColor: AppTheme.cardElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
