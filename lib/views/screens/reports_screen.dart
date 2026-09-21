import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/streaming_controller.dart';
import '../../controllers/reports_controller.dart';
import '../components/stat_card_widget.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA / PANTALLA] ReportsScreen
/// ============================================================================
/// Pantalla de Reportes Financieros y Análisis de Ganancias del negocio.
/// Muestra:
/// 1. Tarjetas KPI: Ganancia Neta Total, Ventas Totales, Costo Total, Margen %
/// 2. Balance de Dinero Recaudado vs Dinero Pendiente de Cobro
/// 3. Desglose detallado de Rentabilidad por Servicio (Netflix, Prime Video, etc.)
/// 4. Desglose de Gastos y Rentabilidad por Proveedor (Digital House, S.G.R)
/// ============================================================================
class ReportsScreen extends StatelessWidget {
  final StreamingController controller;

  const ReportsScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final accounts = controller.accounts;

        final totalVentas = ReportsController.totalVentas(accounts);
        final totalCostos = ReportsController.totalCostos(accounts);
        final gananciaNeta = ReportsController.gananciaNeta(accounts);
        final margenPorcentaje = ReportsController.margenPorcentaje(accounts);
        final dineroRecaudado = ReportsController.dineroRecaudado(accounts);
        final dineroPorCobrar = ReportsController.dineroPorCobrar(accounts);
        final desgloseServicios = ReportsController.desglosePorServicio(accounts);
        final desgloseProveedores = ReportsController.desglosePorProveedor(accounts);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de Sección
                const Text(
                  'RESUMEN FINANCIERO',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // Tarjeta Principal Destacada: Ganancia Neta
                StatCardWidget(
                  titulo: 'Ganancia Neta Total',
                  valor: gananciaNeta,
                  icono: Icons.trending_up_rounded,
                  colorAcento: AppTheme.successGreen,
                  subtitulo: 'Margen de Utilidad: ${margenPorcentaje.toStringAsFixed(1)}%',
                  esDestacado: true,
                ),

                const SizedBox(height: 12),

                // Grid 2x1: Total Ventas y Costos Invertidos
                Row(
                  children: [
                    Expanded(
                      child: StatCardWidget(
                        titulo: 'Ventas Totales',
                        valor: totalVentas,
                        icono: Icons.point_of_sale_rounded,
                        colorAcento: AppTheme.netflixRed,
                        subtitulo: '${accounts.length} pantallas',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCardWidget(
                        titulo: 'Costo Inversión',
                        valor: totalCostos,
                        icono: Icons.account_balance_wallet_rounded,
                        colorAcento: AppTheme.infoBlue,
                        subtitulo: 'A proveedores',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Balance de Recaudo (Cobrado vs Por Cobrar)
                const Text(
                  'ESTADO DE RECAUDO',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),

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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              const Text('Recaudado (PAGO)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                          Text(
                            formatoMoneda.format(dineroRecaudado),
                            style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(color: AppTheme.warningAmber, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              const Text('Por Cobrar (PENDIENTE)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                          Text(
                            formatoMoneda.format(dineroPorCobrar),
                            style: const TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Desglose por Servicio
                const Text(
                  'RENTABILIDAD POR SERVICIO',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),

                ...desgloseServicios.entries.map((entry) {
                  final servicio = entry.key;
                  final datos = entry.value;
                  final cant = datos['cantidad'] as int;
                  final ganancia = datos['ganancia'] as double;
                  final ventas = datos['ventas'] as double;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.netflixRed.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.tv_rounded, color: AppTheme.netflixRed, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  servicio,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '$cant pantallas vendidas',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+${formatoMoneda.format(ganancia)}',
                              style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            Text(
                              'Venta: ${formatoMoneda.format(ventas)}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Desglose por Proveedor
                const Text(
                  'COMPRAS Y GANANCIAS POR PROVEEDOR',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),

                ...desgloseProveedores.entries.map((entry) {
                  final prov = entry.key;
                  final datos = entry.value;
                  final cant = datos['cantidad'] as int;
                  final costos = datos['costos'] as double;
                  final ganancia = datos['ganancia'] as double;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prov,
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Costo Pagado: ${formatoMoneda.format(costos)} ($cant ctas)',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${formatoMoneda.format(ganancia)} ganancia',
                            style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
