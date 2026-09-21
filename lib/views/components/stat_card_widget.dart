import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [WIDGET / VISTA] StatCardWidget
/// ============================================================================
/// Widget reutilizable para mostrar tarjetas de métricas e indicadores (KPIs).
/// Características:
/// - Título de la métrica (ej. "Ganancia Neta", "Total Ventas", "Inversión")
/// - Valor monetario formateado en pesos ($ COP)
/// - Icono temático con contenedor iluminado
/// - Subtítulo informativo (ej. "Margen del 65%", "8 pantallas")
/// ============================================================================
class StatCardWidget extends StatelessWidget {
  final String titulo;
  final double valor;
  final IconData icono;
  final Color colorAcento;
  final String? subtitulo;
  final bool esDestacado;

  const StatCardWidget({
    Key? key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.colorAcento = AppTheme.netflixRed,
    this.subtitulo,
    this.esDestacado = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Formateador de moneda colombiana / estándar ($ 14.000)
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esDestacado ? null : AppTheme.cardBg,
        gradient: esDestacado ? AppTheme.profitGradient : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esDestacado
              ? AppTheme.successGreen.withOpacity(0.4)
              : AppTheme.borderSubtle,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Fila Superior: Icono y Título
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo.toUpperCase(),
                style: TextStyle(
                  color: esDestacado ? Colors.white70 : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorAcento.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  color: colorAcento,
                  size: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Valor monetario principal
          Text(
            formatoMoneda.format(valor),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),

          // Subtítulo informativo
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: TextStyle(
                color: esDestacado ? Colors.white.withOpacity(0.85) : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
