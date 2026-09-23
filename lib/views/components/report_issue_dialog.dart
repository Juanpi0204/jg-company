import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/streaming_account_model.dart';
import '../../models/provider_model.dart';
import '../screens/providers_screen.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [MODAL / DIALOG] ReportIssueDialog — Reporte de Falla a Soporte del Proveedor
/// ============================================================================
/// Permite al administrador seleccionar la falla que presenta la pantalla de
/// Netflix o streaming (ej: No forma parte del hogar, PIN incorrecto, clave cambiada, etc.)
/// y enviarla formateada por WhatsApp directo al número de soporte del proveedor.
/// ============================================================================
class ReportIssueDialog extends StatefulWidget {
  final StreamingAccountModel account;

  const ReportIssueDialog({Key? key, required this.account}) : super(key: key);

  static Future<void> mostrar(BuildContext context, StreamingAccountModel account) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ReportIssueDialog(account: account),
      );

  @override
  State<ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<ReportIssueDialog> {
  late TextEditingController _telefonoCtrl;
  late TextEditingController _proveedorCtrl;
  final TextEditingController _detalleCtrl = TextEditingController();

  String? _fallaSeleccionada;

  // Lista de fallas más comunes de Netflix y servicios de streaming
  final List<Map<String, dynamic>> _fallasComunes = [
    {
      'titulo': 'No forma parte del hogar de Netflix',
      'subtitulo': 'Pide actualizar hogar o código temporal de viaje',
      'icono': Icons.home_work_rounded,
      'accion': 'Solicito código de actualización temporal de hogar.',
    },
    {
      'titulo': 'PIN de perfil incorrecto',
      'subtitulo': 'El PIN no abre el perfil o fue cambiado',
      'icono': Icons.lock_outline_rounded,
      'accion': 'El cliente no puede ingresar a su perfil por PIN inválido.',
    },
    {
      'titulo': 'Contraseña incorrecta / Cambiaron la clave',
      'subtitulo': 'No permite iniciar sesión en la cuenta',
      'icono': Icons.key_off_rounded,
      'accion': 'La clave actual no funciona. Solicito clave actualizada.',
    },
    {
      'titulo': 'Muchos dispositivos vinculados / Límite alcanzado',
      'subtitulo': 'Demasiadas pantallas viendo al mismo tiempo',
      'icono': Icons.devices_other_rounded,
      'accion': 'Indica que hay demasiadas personas usando la cuenta en simultáneo.',
    },
    {
      'titulo': 'Cuenta suspendida / Problema de facturación',
      'subtitulo': 'Membresía pausada o rechazo en método de pago',
      'icono': Icons.credit_card_off_rounded,
      'accion': 'Aparece aviso de cuenta suspendida por falta de pago del proveedor.',
    },
    {
      'titulo': 'Perfil borrado o cambiado de nombre',
      'subtitulo': 'El perfil asignado ya no existe o tiene otro nombre',
      'icono': Icons.person_remove_rounded,
      'accion': 'El perfil del cliente fue modificado o eliminado.',
    },
    {
      'titulo': 'Error en pantalla / Código de error en TV',
      'subtitulo': 'Error técnico en Smart TV o consola (ej: ui-800, nw-2-5)',
      'icono': Icons.tv_off_rounded,
      'accion': 'La aplicación arroja un código de error al reproducir contenido.',
    },
    {
      'titulo': 'Otra falla...',
      'subtitulo': 'Escribir detalle personalizado manualmente',
      'icono': Icons.edit_note_rounded,
      'accion': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _proveedorCtrl = TextEditingController(text: widget.account.proveedor);
    _telefonoCtrl = TextEditingController();
    _buscarTelefonoProveedor();
  }

  Future<void> _buscarTelefonoProveedor() async {
    final prov = await ProvidersService.findByNombre(widget.account.proveedor);
    if (mounted) {
      setState(() {
        if (prov != null && prov.telefono.isNotEmpty) {
          _telefonoCtrl.text = prov.telefono;
        }
      });
    }
  }

  @override
  void dispose() {
    _proveedorCtrl.dispose();
    _telefonoCtrl.dispose();
    _detalleCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarProveedor() async {
    final prov = await ProviderSelectorDialog.mostrar(context);
    if (prov != null && mounted) {
      setState(() {
        _proveedorCtrl.text = prov.nombre;
        if (prov.telefono.isNotEmpty) {
          _telefonoCtrl.text = prov.telefono;
        }
      });
    }
  }

  Future<void> _enviarReporteWhatsApp() async {
    if (_fallaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la falla que presenta la cuenta'),
          backgroundColor: AppTheme.warningAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawPhone = _telefonoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el número de WhatsApp de soporte del proveedor'),
          backgroundColor: AppTheme.netflixRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String phoneFormatted = rawPhone;
    if (phoneFormatted.length == 10 && phoneFormatted.startsWith('3')) {
      phoneFormatted = '57$phoneFormatted';
    }

    final acc = widget.account;
    final itemFalla = _fallasComunes.firstWhere((f) => f['titulo'] == _fallaSeleccionada);
    final String detalleExtra = _detalleCtrl.text.trim().isNotEmpty
        ? _detalleCtrl.text.trim()
        : (itemFalla['accion'] as String? ?? '');

    final mensaje = '''
🚨 *REPORTE DE FALLA TÉCNICA - JG COMPANY S.A.S* 🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━
Hola, solicitamos soporte técnico para la siguiente pantalla:

📺 *Servicio:* ${acc.servicio}
📧 *Cuenta:* ${acc.cuenta}
🔑 *Contraseña:* ${acc.clave}
🔢 *Perfil:* ${acc.perfil}
🔒 *PIN:* ${acc.pin.isNotEmpty ? acc.pin : 'Sin PIN'}
👤 *Cliente:* ${acc.cliente}
🏢 *Proveedor:* ${_proveedorCtrl.text.isNotEmpty ? _proveedorCtrl.text : acc.proveedor}

⚠️ *FALLA REPORTADA:*
👉 *$_fallaSeleccionada*
${detalleExtra.isNotEmpty ? '📝 *Detalle:* $detalleExtra\n' : ''}━━━━━━━━━━━━━━━━━━━━━━━━━━
_Agradecemos su pronta revisión para solucionar al cliente a la brevedad. ¡Muchas gracias!_
''';

    final encodedMessage = Uri.encodeComponent(mensaje).replaceAll('%2B', '%252B');
    final uri = Uri.parse('https://wa.me/$phoneFormatted?text=$encodedMessage');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception('No se pudo abrir WhatsApp');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir WhatsApp: $e'),
            backgroundColor: AppTheme.netflixRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141418),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Asa superior
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 42, height: 4,
              decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
            ),

            // Encabezado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.netflixRed.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.report_problem_rounded, color: AppTheme.netflixRed, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reportar Falla a Soporte',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
                        Text('Envía el diagnóstico automático por WhatsApp al proveedor',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Resumen de la Pantalla en Tarjeta Compacta
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(acc.servicio,
                                style: const TextStyle(color: AppTheme.netflixRed, fontWeight: FontWeight.w900, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.cardElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Perfil ${acc.perfil} (PIN: ${acc.pin.isNotEmpty ? acc.pin : "0"})',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(acc.cuenta,
                            style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'monospace', fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text('Cliente: ${acc.cliente}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sección: Proveedor y Teléfono de WhatsApp
                  const Text('PROVEEDOR Y WHATSAPP DE SOPORTE',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _proveedorCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Proveedor',
                            labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            prefixIcon: const Icon(Icons.business_rounded, color: AppTheme.textMuted, size: 18),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.contacts_rounded, color: AppTheme.purpleAccent, size: 18),
                              tooltip: 'Seleccionar proveedor',
                              onPressed: _seleccionarProveedor,
                            ),
                            filled: true, fillColor: AppTheme.cardBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _telefonoCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'WhatsApp Soporte',
                            labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            prefixIcon: const Icon(Icons.support_agent_rounded, color: AppTheme.successGreen, size: 18),
                            filled: true, fillColor: AppTheme.cardBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Selector de Falla Reportada
                  const Text('SELECCIONA LA FALLA PRESENTADA',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),

                  ..._fallasComunes.map((falla) {
                    final isSelected = _fallaSeleccionada == falla['titulo'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.netflixRed.withOpacity(0.12) : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.netflixRed : AppTheme.borderSubtle,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _fallaSeleccionada = falla['titulo'];
                          });
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.netflixRed : AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            falla['icono'] as IconData,
                            color: isSelected ? Colors.white : AppTheme.textMuted,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          falla['titulo'],
                          style: TextStyle(
                            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          falla['subtitulo'],
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.netflixRed, size: 20)
                            : const Icon(Icons.radio_button_unchecked_rounded, color: AppTheme.textMuted, size: 20),
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // Campo para detalle adicional
                  TextField(
                    controller: _detalleCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Detalle adicional / Observación opcional (ej. Smart TV Samsung, pide código de 4 dígitos)...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      filled: true, fillColor: AppTheme.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón Enviar Reporte por WhatsApp
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _enviarReporteWhatsApp,
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'ENVIAR REPORTE POR WHATSAPP 📲',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
