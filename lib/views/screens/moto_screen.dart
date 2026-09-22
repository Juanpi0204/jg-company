import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA / PANTALLA] MotoScreen — Control de Kilometraje y Aceite
/// ============================================================================
/// - Km actual del tablero (ingresado manualmente)
/// - Intervalo de cambio personalizable (el usuario define cada cuántos km)
/// - Km del último cambio (se registra cuando haces el cambio)
/// - Alertas: 🟢 Óptimo, 🟡 Próximo, 🔴 Urgente
/// ============================================================================
class MotoScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  const MotoScreen({Key? key, required this.onOpenDrawer}) : super(key: key);

  @override
  State<MotoScreen> createState() => _MotoScreenState();
}

class _MotoScreenState extends State<MotoScreen> {
  double _kmActual        = 12500;
  double _ultimoCambioKm  = 10000;
  double _intervaloCambio = 3000; // km entre cambios — el usuario lo configura

  final _kmInputCtrl        = TextEditingController();
  final _intervaloInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _kmInputCtrl.dispose();
    _intervaloInputCtrl.dispose();
    super.dispose();
  }

  // ── Persistencia ──────────────────────────────────────────────────────────
  Future<void> _cargar() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _kmActual        = p.getDouble('moto_km_actual')    ?? 12500;
      _ultimoCambioKm  = p.getDouble('moto_ultimo_cambio') ?? 10000;
      _intervaloCambio = p.getDouble('moto_intervalo')     ?? 3000;
      _kmInputCtrl.text        = _kmActual.toStringAsFixed(0);
      _intervaloInputCtrl.text = _intervaloCambio.toStringAsFixed(0);
    });
  }

  Future<void> _guardar() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('moto_km_actual',    _kmActual);
    await p.setDouble('moto_ultimo_cambio', _ultimoCambioKm);
    await p.setDouble('moto_intervalo',    _intervaloCambio);
  }

  // ── Cálculos ──────────────────────────────────────────────────────────────
  double get _proximoCambioKm => _ultimoCambioKm + _intervaloCambio;
  double get _kmRestantes     => _proximoCambioKm - _kmActual;
  double get _porcentajeUso   =>
      ((_kmActual - _ultimoCambioKm) / _intervaloCambio).clamp(0.0, 1.0);

  // ── Acciones ──────────────────────────────────────────────────────────────
  void _guardarKm() {
    final v = double.tryParse(_kmInputCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
    if (v != null && v > 0) {
      setState(() => _kmActual = v);
      _guardar();
      Navigator.pop(context);
      _snack('Kilometraje actualizado a ${v.toStringAsFixed(0)} km', AppTheme.netflixRed);
    }
  }

  void _guardarIntervalo() {
    final v = double.tryParse(_intervaloInputCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
    if (v != null && v >= 500) {
      setState(() => _intervaloCambio = v);
      _guardar();
      Navigator.pop(context);
      _snack('Intervalo configurado a ${v.toStringAsFixed(0)} km', AppTheme.successGreen);
    } else {
      _snack('El intervalo mínimo es 500 km', AppTheme.warningAmber);
    }
  }

  void _registrarCambioHoy() {
    setState(() => _ultimoCambioKm = _kmActual);
    _guardar();
    _snack('¡Cambio de aceite registrado en ${_kmActual.toStringAsFixed(0)} km!', AppTheme.successGreen);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Diálogos ─────────────────────────────────────────────────────────────
  void _dialogoKm() {
    _kmInputCtrl.text = _kmActual.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        titulo: 'Actualizar Odómetro',
        icono: Icons.edit_road_rounded,
        iconColor: AppTheme.netflixRed,
        descripcion: 'Ingresa el kilometraje que marca actualmente tu moto en el tablero.',
        campo: _buildCampoNumero(_kmInputCtrl, 'KM actual del tablero', 'KM'),
        onGuardar: _guardarKm,
        ctx: ctx,
      ),
    );
  }

  void _dialogoIntervalo() {
    _intervaloInputCtrl.text = _intervaloCambio.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        titulo: 'Configurar Intervalo',
        icono: Icons.settings_rounded,
        iconColor: AppTheme.warningAmber,
        descripcion: 'Define cada cuántos km debe hacerse el cambio de aceite.\nEjemplo: 2500 km, 3000 km, 5000 km.',
        campo: _buildCampoNumero(_intervaloInputCtrl, 'Cada cuántos km', 'KM'),
        onGuardar: _guardarIntervalo,
        ctx: ctx,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'es_CO');

    final Color estadoColor;
    final String estadoTitulo;
    final String estadoDesc;
    final IconData estadoIcon;

    if (_kmRestantes <= 0) {
      estadoColor  = AppTheme.netflixRed;
      estadoTitulo = '¡CAMBIO URGENTE!';
      estadoDesc   = 'Excediste el límite por ${fmt.format(_kmRestantes.abs())} km';
      estadoIcon   = Icons.error_rounded;
    } else if (_kmRestantes <= (_intervaloCambio * 0.15)) {
      // Alerta cuando queda menos del 15% del intervalo
      estadoColor  = AppTheme.warningAmber;
      estadoTitulo = 'PRÓXIMO AL CAMBIO';
      estadoDesc   = 'Solo te quedan ${fmt.format(_kmRestantes)} km más';
      estadoIcon   = Icons.warning_amber_rounded;
    } else {
      estadoColor  = AppTheme.successGreen;
      estadoTitulo = 'ACEITE EN BUEN ESTADO';
      estadoDesc   = 'Faltan ${fmt.format(_kmRestantes)} km para el próximo cambio';
      estadoIcon   = Icons.check_circle_rounded;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── HEADER ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onOpenDrawer,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary, size: 21),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: AppTheme.warningAmber, size: 21),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('CONTROL DE MOTO',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
                          Text('Kilometraje & Aceite',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── TARJETA HÉROE ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22222C), Color(0xFF15151A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: estadoColor.withOpacity(0.45), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: estadoColor.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Estado badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(estadoIcon, color: estadoColor, size: 17),
                            const SizedBox(width: 6),
                            Text(estadoTitulo,
                                style: TextStyle(color: estadoColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(_porcentajeUso * 100).toStringAsFixed(0)}% usado',
                            style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Km actual grande
                    Text(
                      '${fmt.format(_kmActual)} KM',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const Text('KILOMETRAJE ACTUAL DEL TABLERO',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),

                    const SizedBox(height: 18),

                    // Barra de progreso
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.cardElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _porcentajeUso,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: estadoColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [BoxShadow(color: estadoColor.withOpacity(0.5), blurRadius: 6)],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(estadoDesc,
                        style: TextStyle(color: estadoColor, fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── MÉTRICAS ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _metricTile('ÚLTIMO CAMBIO',    '${fmt.format(_ultimoCambioKm)} km',   Icons.history_rounded,       AppTheme.textSecondary)),
                  const SizedBox(width: 10),
                  Expanded(child: _metricTile('PRÓXIMO CAMBIO',   '${fmt.format(_proximoCambioKm)} km',  Icons.flag_rounded,          AppTheme.warningAmber)),
                  const SizedBox(width: 10),
                  Expanded(child: _metricTile('INTERVALO',        '${fmt.format(_intervaloCambio)} km',  Icons.settings_rounded,      AppTheme.infoBlue)),
                ],
              ),

              const SizedBox(height: 24),

              // ── SECCIÓN CONFIGURACIÓN INTERVALO ─────────────────────────
              _seccionLabel('CONFIGURACIÓN'),
              const SizedBox(height: 12),

              // Botón configurar intervalo — EL USUARIO define cuántos km
              _botonAccion(
                icono: Icons.tune_rounded,
                label: 'CONFIGURAR INTERVALO DE CAMBIO',
                sublabel: 'Actualmente cada ${fmt.format(_intervaloCambio)} km',
                color: AppTheme.warningAmber,
                onTap: _dialogoIntervalo,
                outlined: true,
              ),

              const SizedBox(height: 12),

              // ── SECCIÓN ACCIONES ─────────────────────────────────────────
              _seccionLabel('ACCIONES'),
              const SizedBox(height: 12),

              _botonAccion(
                icono: Icons.edit_road_rounded,
                label: 'ACTUALIZAR KILÓMETROS DEL TABLERO',
                sublabel: 'Registra el km que ves en el odómetro',
                color: AppTheme.netflixRed,
                onTap: _dialogoKm,
              ),

              const SizedBox(height: 10),

              _botonAccion(
                icono: Icons.oil_barrel_rounded,
                label: 'REGISTRAR CAMBIO DE ACEITE HOY',
                sublabel: 'Se guardará el km actual como referencia',
                color: AppTheme.successGreen,
                onTap: _registrarCambioHoy,
                outlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ────────────────────────────────────────────────────────────
  Widget _seccionLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppTheme.textMuted.withOpacity(0.7),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
    ),
  );

  Widget _metricTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 5),
            Expanded(child: Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _botonAccion({
    required IconData icono,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(outlined ? 0.4 : 0.25), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(color: outlined ? color : AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    const SizedBox(height: 2),
                    Text(sublabel,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Diálogo genérico ──────────────────────────────────────────────────────
  Widget _buildDialog({
    required String titulo,
    required IconData icono,
    required Color iconColor,
    required String descripcion,
    required Widget campo,
    required VoidCallback onGuardar,
    required BuildContext ctx,
  }) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icono, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Text(titulo, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(descripcion, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          campo,
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: onGuardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.netflixRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildCampoNumero(TextEditingController ctrl, String hint, String suffix) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppTheme.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
      ),
    );
  }
}
