import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/streaming_account_model.dart';
import '../../controllers/streaming_controller.dart';
import '../theme/app_theme.dart';
import 'smart_paste_dialog.dart';
import 'report_issue_dialog.dart';

/// ============================================================================
/// [WIDGET / VISTA] AccountDetailSheet
/// ============================================================================
/// Modal inferior estilo iOS (Bottom Sheet) que se despliega al tocar un cliente.
/// Muestra TODOS los datos detallados de la cuenta y pantalla:
/// 1. Proveedor (DIGITAL HOUSE, S.G.R STREAMING)
/// 2. Servicio (NETFLIX PA, PRIME VIDEO)
/// 3. Credenciales de acceso (Correo y Contraseña con botón de ver/ocultar)
/// 4. Perfil y PIN de bloqueo
/// 5. Fechas de Compra y Vencimiento con contador de días restantes
/// 6. Datos financieros: Costo de Compra, Precio de Venta, Ganancia Neta y Margen %
/// 7. Vendedor responsable
/// 8. Botones de acción: Copiar datos, Enviar a WhatsApp, Editar y Eliminar
/// ============================================================================
class AccountDetailSheet extends StatefulWidget {
  final StreamingAccountModel account;
  final StreamingController controller;
  final Function(StreamingAccountModel) onEdit;

  const AccountDetailSheet({
    Key? key,
    required this.account,
    required this.controller,
    required this.onEdit,
  }) : super(key: key);

  @override
  State<AccountDetailSheet> createState() => _AccountDetailSheetState();
}

class _AccountDetailSheetState extends State<AccountDetailSheet> {
  bool _mostrarClave = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final diasRestantes = widget.account.fechaVencimiento.difference(DateTime.now()).inDays;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de arrastre + botón X de cierre (siempre visible)
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.textMuted.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // X para cerrar sin tener que hacer scroll
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.textMuted, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Encabezado del Modal: Nombre Cliente + Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account.cliente.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vendido por: ${widget.account.vendedor}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge interactivo para cambiar estado de pago
                  GestureDetector(
                    onTap: () async {
                      await widget.controller.togglePaymentStatus(widget.account.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.account.estaPagado
                            ? AppTheme.successGreen.withOpacity(0.15)
                            : AppTheme.warningAmber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.account.estaPagado
                              ? AppTheme.successGreen
                              : AppTheme.warningAmber,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        widget.account.estado,
                        style: TextStyle(
                          color: widget.account.estaPagado
                              ? AppTheme.successGreen
                              : AppTheme.warningAmber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Tarjeta Resumen Financiero (Ganancia, Costo y Venta)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFinanceCol('VENTA', formatoMoneda.format(widget.account.valorVenta), AppTheme.textPrimary),
                    Container(width: 1, height: 35, color: AppTheme.borderLight),
                    _buildFinanceCol('COSTO', formatoMoneda.format(widget.account.valorCompra), AppTheme.textSecondary),
                    Container(width: 1, height: 35, color: AppTheme.borderLight),
                    _buildFinanceCol('GANANCIA', '+${formatoMoneda.format(widget.account.ganancia)}', AppTheme.successGreen, esBold: true),
                  ],
                ),
              ),

              // Bloque de Acciones — diseño limpio sin colores de fondo
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    // ── Renovar servicio ──────────────────────────────────
                    _buildActionTile(
                      icon: Icons.autorenew_rounded,
                      iconColor: AppTheme.successGreen,
                      label: 'Renovar Servicio (+30 días)',
                      sublabel: 'Extiende la fecha de vencimiento',
                      onTap: () async {
                        await widget.controller.renewAccount(widget.account.id, context);
                        if (context.mounted) Navigator.pop(context);
                      },
                      showDivider: true,
                    ),
                    // ── Pegar de Proveedor ────────────────────────────────
                    _buildActionTile(
                      icon: Icons.auto_awesome,
                      iconColor: AppTheme.purpleAccent,
                      label: 'Actualizar datos del Proveedor',
                      sublabel: 'Pegar mensaje con nueva clave / cuenta',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => SmartPasteDialog(
                            onResult: (result) async {
                              await widget.controller.updateCredentials(
                                widget.account.id,
                                cuenta: result.correo,
                                clave: result.clave,
                                pin: result.pin,
                                perfil: result.perfil,
                                proveedor: result.proveedor,
                                servicio: result.servicio,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('¡Datos de la pantalla actualizados con éxito!'),
                                    backgroundColor: AppTheme.netflixRed,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                          ),
                        );
                      },
                      showDivider: true,
                    ),
                    // ── Enviar clave nueva por WhatsApp ───────────────────
                    _buildActionTile(
                      icon: Icons.key_rounded,
                      iconColor: AppTheme.warningAmber,
                      label: 'Enviar nueva clave por WhatsApp',
                      sublabel: 'Notifica la clave actualizada al cliente',
                      onTap: () => widget.controller.sendNewPasswordWhatsApp(widget.account),
                      showDivider: true,
                    ),
                    // ── Avisar vencimiento ────────────────────────────────
                    _buildActionTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: widget.account.esPorVencer || widget.account.esVencida
                          ? AppTheme.warningAmber
                          : AppTheme.textSecondary,
                      label: widget.account.esPorVencer || widget.account.esVencida
                          ? '⚠️ Avisar Vencimiento (urgente)'
                          : 'Avisar Vencimiento por WhatsApp',
                      sublabel: 'Envía recordatorio al cliente',
                      onTap: () => widget.controller.sendRenewalReminderWhatsApp(widget.account),
                      showDivider: true,
                    ),
                    // ── Reportar falla ────────────────────────────────────
                    _buildActionTile(
                      icon: Icons.report_problem_rounded,
                      iconColor: AppTheme.netflixRed,
                      label: 'Reportar Falla a Soporte 🚨',
                      sublabel: 'Envía reporte al proveedor',
                      onTap: () => ReportIssueDialog.mostrar(context, widget.account),
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'DATOS DE ACCESO Y PANTALLA',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              // Bloque de Credenciales
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.tv_rounded,
                      'Servicio',
                      widget.account.servicio,
                      colorValor: AppTheme.netflixRed,
                    ),
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    _buildDetailRow(
                      Icons.business_rounded,
                      'Proveedor',
                      widget.account.proveedor,
                    ),
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    _buildDetailRow(
                      Icons.mail_outline_rounded,
                      'Correo / Cuenta',
                      widget.account.cuenta,
                      copiable: true,
                    ),
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    _buildDetailRow(
                      Icons.lock_outline_rounded,
                      'Contraseña',
                      _mostrarClave ? widget.account.clave : '••••••••••••',
                      trailing: IconButton(
                        icon: Icon(
                          _mostrarClave ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _mostrarClave = !_mostrarClave),
                      ),
                      copiable: true,
                      valorRealParaCopiar: widget.account.clave,
                    ),
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    _buildDetailRow(
                      Icons.person_pin_circle_rounded,
                      'Perfil Asignado',
                      'Perfil ${widget.account.perfil}',
                    ),
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    _buildDetailRow(
                      Icons.pin_rounded,
                      'PIN de Bloqueo',
                      widget.account.pin.isNotEmpty ? widget.account.pin : 'Sin PIN',
                      colorValor: AppTheme.warningAmber,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'FECHAS Y VIGENCIA',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              // Bloque de Fechas
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fecha de Compra', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(dateFormat.format(widget.account.fechaCompra), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Vencimiento', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFormat.format(widget.account.fechaVencimiento)} (${diasRestantes > 0 ? '$diasRestantes días' : 'Vencida'})',
                          style: TextStyle(
                            color: diasRestantes <= 3 ? AppTheme.warningAmber : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (widget.account.notas.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes, color: AppTheme.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.account.notas,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Botones Principales de Acción
              Row(
                children: [
                  // Botón Copiar Credenciales
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => widget.controller.copyCredentials(widget.account, context),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardElevated,
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Botón Enviar a WhatsApp
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => widget.controller.sendWhatsApp(widget.account),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Botones Secundarios: Editar y Eliminar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onEdit(widget.account);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar Cuenta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.netflixRed),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.cardBg,
                          title: const Text('¿Eliminar Cuenta?'),
                          content: Text('Se eliminará la cuenta de ${widget.account.cliente}.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar', style: TextStyle(color: AppTheme.netflixRed)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await widget.controller.deleteAccount(widget.account.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceCol(String label, String value, Color color, {bool esBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: esBold ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value, {
    Color? colorValor,
    Widget? trailing,
    bool copiable = false,
    String? valorRealParaCopiar,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: colorValor ?? AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  /// Tile de acción limpio: icono coloreado + label + sublabel + flecha
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 1),
                      Text(sublabel,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 18),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 62, color: AppTheme.borderSubtle),
      ],
    );
  }
}

