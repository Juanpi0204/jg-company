import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/streaming_account_model.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [WIDGET / VISTA] ClientCardWidget
/// ============================================================================
/// Tarjeta táctil interactiva que representa a un cliente y su pantalla asignada.
/// Características:
/// - Avatar con inicial y color distintivo según el servicio (Netflix, Prime, etc.)
/// - Nombre del cliente en blanco destacado
/// - Correo y Perfil / PIN
/// - Badge de estado de pago: 'PAGO' (Verde) o 'PENDIENTE' (Ámbar)
/// - Precio de venta y Ganancia neta
/// - Botón directo de WhatsApp para enviar credenciales con 1 toque
/// - Al tocar la tarjeta, dispara `onTap` para abrir el modal de detalles completos
/// ============================================================================
class ClientCardWidget extends StatelessWidget {
  final StreamingAccountModel account;
  final VoidCallback onTap;
  final VoidCallback onWhatsAppTap;
  final VoidCallback onTogglePayment;
  final VoidCallback? onRenewalReminderTap;
  final VoidCallback? onReportIssueTap;

  const ClientCardWidget({
    Key? key,
    required this.account,
    required this.onTap,
    required this.onWhatsAppTap,
    required this.onTogglePayment,
    this.onRenewalReminderTap,
    this.onReportIssueTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    // Determinar color e inicial según el servicio
    final bool esNetflix = account.servicio.toUpperCase().contains('NETFLIX');
    final Color colorServicio = esNetflix ? AppTheme.netflixRed : AppTheme.infoBlue;
    final String inicialServicio = esNetflix ? 'N' : 'P';

    // Determinar color y texto de semáforo
    Color colorSemaforo;
    String textoSemaforo;
    IconData iconSemaforo;

    if (account.esVencida) {
      colorSemaforo = AppTheme.netflixRed;
      textoSemaforo = '🔴 VENCIDA (${account.diasRestantes.abs()}d)';
      iconSemaforo = Icons.cancel_rounded;
    } else if (account.esPorVencer) {
      colorSemaforo = AppTheme.warningAmber;
      textoSemaforo = '🟡 POR VENCER (${account.diasRestantes}d)';
      iconSemaforo = Icons.warning_amber_rounded;
    } else {
      colorSemaforo = AppTheme.successGreen;
      textoSemaforo = '🟢 ACTIVA (${account.diasRestantes}d)';
      iconSemaforo = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: account.esPorVencer
              ? AppTheme.warningAmber.withOpacity(0.6)
              : account.esVencida
                  ? AppTheme.netflixRed.withOpacity(0.5)
                  : AppTheme.borderSubtle,
          width: account.esPorVencer || account.esVencida ? 1.5 : 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila Superior: Avatar + Nombre Cliente + Badge Estado Pago
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar del servicio
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorServicio.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorServicio.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          inicialServicio,
                          style: TextStyle(
                            color: colorServicio,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nombre del cliente y servicio
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.cliente.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                account.servicio,
                                style: TextStyle(
                                  color: colorServicio,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
                              Text(
                                'Perfil ${account.perfil}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Badge de Estado de Pago (táctil para cambiar rápido)
                    GestureDetector(
                      onTap: onTogglePayment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: account.estaPagado
                              ? AppTheme.successGreen.withOpacity(0.15)
                              : AppTheme.warningAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: account.estaPagado
                                ? AppTheme.successGreen
                                : AppTheme.warningAmber,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              account.estaPagado ? Icons.check_circle : Icons.access_time_filled,
                              size: 12,
                              color: account.estaPagado
                                  ? AppTheme.successGreen
                                  : AppTheme.warningAmber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              account.estado,
                              style: TextStyle(
                                color: account.estaPagado
                                    ? AppTheme.successGreen
                                    : AppTheme.warningAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Barra Semáforo de Vigencia
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorSemaforo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorSemaforo.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(iconSemaforo, color: colorSemaforo, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            textoSemaforo,
                            style: TextStyle(
                              color: colorSemaforo,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      if (account.esPorVencer && onRenewalReminderTap != null)
                        GestureDetector(
                          onTap: onRenewalReminderTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warningAmber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.notifications_active_rounded, size: 11, color: Colors.black),
                                SizedBox(width: 4),
                                Text(
                                  'Avisar WhatsApp',
                                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Fila Central: Correo electrónico y PIN
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          account.cuenta,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (account.pin.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.cardElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PIN: ${account.pin}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Fila Inferior: Valores financieros + Botón WhatsApp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Valor y ganancia
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              formatoMoneda.format(account.valorVenta),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${formatoMoneda.format(account.ganancia)} ganancia',
                                style: const TextStyle(
                                  color: AppTheme.successGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Proveedor: ${account.proveedor}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onReportIssueTap != null) ...[
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onReportIssueTap,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.netflixRed.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.netflixRed.withOpacity(0.35),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.report_problem_rounded, color: AppTheme.netflixRed, size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'Falla',
                                      style: TextStyle(
                                        color: AppTheme.netflixRed,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Botón directo para enviar credenciales por WhatsApp
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onWhatsAppTap,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF25D366).withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Enviar',
                                    style: TextStyle(
                                      color: Color(0xFF25D366),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
