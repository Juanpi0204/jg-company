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
              // Barra de arrastre superior típica de iOS
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

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

              // Bloque de Acciones Inteligentes: Renovación y Cambio de Clave
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    // Botón Renovar +30 Días (Verde)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await widget.controller.renewAccount(widget.account.id, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.autorenew_rounded, size: 18),
                        label: const Text('RENOVAR SERVICIO (+30 DÍAS)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Botón Pegar del Proveedor (Cambiar Clave / Cuenta)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
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
                            icon: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.purpleAccent),
                            label: const Text('Pegar de Proveedor'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(color: AppTheme.purpleAccent),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Botón Notificar Nueva Clave
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => widget.controller.sendNewPasswordWhatsApp(widget.account),
                            icon: const Icon(Icons.key_rounded, size: 16, color: AppTheme.warningAmber),
                            label: const Text('Enviar Clave WA'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(color: AppTheme.warningAmber),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Botón Reportar Falla a Soporte del Proveedor
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ReportIssueDialog.mostrar(context, widget.account);
                        },
                        icon: const Icon(Icons.report_problem_rounded, size: 17, color: Colors.white),
                        label: const Text('REPORTAR FALLA A SOPORTE (PROVEEDOR) 🚨'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB81D24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),

                    // Botón de Recordatorio de Vencimiento vía WhatsApp
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.controller.sendRenewalReminderWhatsApp(widget.account),
                        icon: const Icon(Icons.notifications_active_rounded, size: 16),
                        label: Text(
                          widget.account.esPorVencer || widget.account.esVencida
                              ? '⚠️ ENVIAR RECORDATORIO DE VENCIMIENTO WA'
                              : '🔔 AVISAR VENCIMIENTO POR WHATSAPP',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.account.esPorVencer || widget.account.esVencida
                              ? AppTheme.warningAmber
                              : AppTheme.cardElevated,
                          foregroundColor: widget.account.esPorVencer || widget.account.esVencida
                              ? Colors.black
                              : AppTheme.warningAmber,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: AppTheme.warningAmber.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
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
}
