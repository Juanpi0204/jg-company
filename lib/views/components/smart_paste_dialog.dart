import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/smart_parser_service.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [WIDGET / VISTA] SmartPasteDialog (Detector Inteligente de Cuentas)
/// ============================================================================
/// Cuadro de diálogo interactivo donde el usuario puede pegar cualquier texto
/// que le haya enviado un revendedor o proveedor de streaming por WhatsApp.
/// - Analiza el texto en tiempo real con SmartParserService.
/// - Muestra los fragmentos detectados (Correo, Clave, PIN, Perfil, etc.).
/// - Al presionar "Aplicar", transfiere los datos al formulario o cuenta.
/// ============================================================================
class SmartPasteDialog extends StatefulWidget {
  final Function(SmartParsedResult) onResult;

  const SmartPasteDialog({
    Key? key,
    required this.onResult,
  }) : super(key: key);

  @override
  State<SmartPasteDialog> createState() => _SmartPasteDialogState();
}

class _SmartPasteDialogState extends State<SmartPasteDialog> {
  final TextEditingController _textCtrl = TextEditingController();
  SmartParsedResult? _parsedResult;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _analizarTexto(String text) {
    setState(() {
      _parsedResult = SmartParserService.parse(text);
    });
  }

  Future<void> _pegarDelPortapapeles() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _textCtrl.text = data.text!;
      _analizarTexto(data.text!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del Asistente
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.redGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PEGADO INTELIGENTE',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Detector automático de cuentas',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Botón Rápido para Pegar del Portapapeles
              OutlinedButton.icon(
                onPressed: _pegarDelPortapapeles,
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: const Text('Pegar mensaje de WhatsApp'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.netflixRed),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 12),

              // Caja de Texto
              TextField(
                controller: _textCtrl,
                maxLines: 4,
                onChanged: _analizarTexto,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Pega aquí el texto que te mandó el proveedor...\nEj:\nNetflix 1 pantalla\nCorreo: usuario@gmail.com\nClave: 123456\nPerfil 2 Pin 2030',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              // Vista Previa de Fragmentos Detectados
              if (_parsedResult != null && _parsedResult!.tieneDatos) ...[
                const SizedBox(height: 16),
                const Text(
                  'DATOS DETECTADOS POR EL SISTEMA:',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      if (_parsedResult!.servicio != null)
                        _buildDetectedItem('Servicio', _parsedResult!.servicio!, Icons.tv, color: AppTheme.netflixRed),
                      if (_parsedResult!.correo != null)
                        _buildDetectedItem('Correo', _parsedResult!.correo!, Icons.mail_outline),
                      if (_parsedResult!.clave != null)
                        _buildDetectedItem('Clave', _parsedResult!.clave!, Icons.lock_outline, color: AppTheme.warningAmber),
                      if (_parsedResult!.perfil != null)
                        _buildDetectedItem('Perfil', 'Perfil ${_parsedResult!.perfil}', Icons.person_pin),
                      if (_parsedResult!.pin != null)
                        _buildDetectedItem('PIN', _parsedResult!.pin!, Icons.pin_outlined),
                      if (_parsedResult!.proveedor != null)
                        _buildDetectedItem('Proveedor', _parsedResult!.proveedor!, Icons.business),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Botón Aplicar Datos
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_parsedResult != null && _parsedResult!.tieneDatos)
                      ? () {
                          widget.onResult(_parsedResult!);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.netflixRed,
                    disabledBackgroundColor: AppTheme.cardElevated,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppTheme.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'APLICAR A LA PANTALLA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectedItem(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.textMuted),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 14),
        ],
      ),
    );
  }
}
