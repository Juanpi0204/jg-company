import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/debt_model.dart';
import '../../services/cloud_sync_service.dart';
import '../../controllers/streaming_controller.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA / PANTALLA] DebtsScreen — Control de Deudas, Préstamos y Abonos
/// ============================================================================
class DebtsScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final StreamingController? streamingController;

  const DebtsScreen({
    Key? key,
    required this.onOpenDrawer,
    this.streamingController,
  }) : super(key: key);

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<DebtModel> _deudas = [];
  bool _loading = true;
  String _filtro = 'todas'; // 'todas', 'pendientes', 'pagadas'

  @override
  void initState() {
    super.initState();
    DebtsService.notifier.addListener(_recargar);
    _cargar();
  }

  @override
  void dispose() {
    DebtsService.notifier.removeListener(_recargar);
    super.dispose();
  }

  void _recargar() {
    if (mounted) _cargar();
  }

  Future<void> _cargar() async {
    final lista = await DebtsService.getAll();
    if (mounted) {
      setState(() {
        _deudas = lista;
        _loading = false;
      });
    }
  }

  void _syncCloud() {
    if (widget.streamingController != null) {
      CloudSyncService.triggerAutoSync(
        accounts: widget.streamingController!.accounts,
        debts: _deudas,
      );
    }
  }

  List<DebtModel> get _deudasFiltradas {
    if (_filtro == 'pendientes') {
      return _deudas.where((d) => !d.estaPagada).toList();
    } else if (_filtro == 'pagadas') {
      return _deudas.where((d) => d.estaPagada).toList();
    }
    return _deudas;
  }

  void _mostrarFormNuevaDeuda() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NuevaDeudaSheet(
        onGuardar: (acreedor, monto, {descripcion = '', fechaLimite, color}) async {
          await DebtsService.add(
            acreedor: acreedor,
            montoTotal: monto,
            descripcion: descripcion,
            fechaLimite: fechaLimite,
            color: color ?? const Color(0xFFE91E63),
          );
          await _cargar();
          _syncCloud();
        },
      ),
    );
  }

  void _mostrarFormAbono(DebtModel deuda) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NuevoAbonoSheet(
        deuda: deuda,
        onGuardar: (monto, nota) async {
          await DebtsService.addAbono(
            deudaId: deuda.id,
            monto: monto,
            nota: nota,
          );
          await _cargar();
          _syncCloud();
        },
      ),
    );
  }

  void _abrirDetalleDeuda(DebtModel deuda) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleDeudaSheet(
        deuda: deuda,
        onNuevoAbono: () => _mostrarFormAbono(deuda),
        onSyncCloud: _syncCloud,
      ),
    );
  }

  Future<void> _eliminarDeuda(DebtModel d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Eliminar deuda',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Eliminar la deuda con "${d.acreedor}"?\nSe borrará todo su historial de abonos.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.netflixRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DebtsService.delete(d.id);
      await _cargar();
      _syncCloud();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    final totalDeudas = _deudas.fold(0.0, (s, d) => s + d.montoTotal);
    final totalAbonado = _deudas.fold(0.0, (s, d) => s + d.totalAbonado);
    final saldoPendiente = _deudas.fold(0.0, (s, d) => s + d.saldoRestante);
    final porcentajeGlobal = totalDeudas > 0 ? (totalAbonado / totalDeudas).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormNuevaDeuda,
        backgroundColor: const Color(0xFFE91E63),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('NUEVA DEUDA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header Superior ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
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
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Deudas & Préstamos',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            )),
                        Text('Control de acreedores y abonos',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Resumen Global ───────────────────────────────────────────────
            if (_deudas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF880E4F), Color(0xFF4A148C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResumenCol('TOTAL DEUDA', fmt.format(totalDeudas), Colors.white),
                          Container(width: 1, height: 38, color: Colors.white24),
                          _buildResumenCol(
                            '⏳ SALDO PENDIENTE',
                            fmt.format(saldoPendiente),
                            saldoPendiente > 0 ? const Color(0xFFFF8A80) : const Color(0xFF69F0AE),
                          ),
                          Container(width: 1, height: 38, color: Colors.white24),
                          _buildResumenCol(
                            '✅ ABONADO',
                            fmt.format(totalAbonado),
                            const Color(0xFF69F0AE),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: porcentajeGlobal,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF69F0AE)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(porcentajeGlobal * 100).toStringAsFixed(0)}% pagado',
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            saldoPendiente <= 0 ? '🎉 Todas al día' : 'Faltan ${fmt.format(saldoPendiente)}',
                            style: TextStyle(
                              color: saldoPendiente <= 0 ? const Color(0xFF69F0AE) : Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // ── Filtros (Todas / Pendientes / Pagadas) ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  _filtroChip('Todas', 'todas', _deudas.length),
                  const SizedBox(width: 8),
                  _filtroChip('Pendientes', 'pendientes',
                      _deudas.where((d) => !d.estaPagada).length),
                  const SizedBox(width: 8),
                  _filtroChip('Pagadas', 'pagadas',
                      _deudas.where((d) => d.estaPagada).length),
                ],
              ),
            ),

            // ── Lista de Deudas ──────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE91E63), strokeWidth: 2))
                  : _deudasFiltradas.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _deudasFiltradas.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _DeudaCard(
                            deuda: _deudasFiltradas[i],
                            onTap: () => _abrirDetalleDeuda(_deudasFiltradas[i]),
                            onAbonar: () => _mostrarFormAbono(_deudasFiltradas[i]),
                            onEliminar: () => _eliminarDeuda(_deudasFiltradas[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtroChip(String label, String valor, int cantidad) {
    final bool activo = _filtro == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtro = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFE91E63).withOpacity(0.25) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: activo ? const Color(0xFFE91E63) : AppTheme.borderSubtle,
            width: activo ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$label ($cantidad)',
          style: TextStyle(
            color: activo ? Colors.white : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResumenCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.request_quote_rounded,
                color: Color(0xFFE91E63), size: 46),
          ),
          const SizedBox(height: 16),
          const Text('Sin deudas registradas',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Toca "+ NUEVA DEUDA" para registrar a quién o a qué le debes',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ]),
      );
}

/// ============================================================================
/// [WIDGET] _DeudaCard — Tarjeta de deuda individual con saldo y progreso
/// ============================================================================
class _DeudaCard extends StatelessWidget {
  final DebtModel deuda;
  final VoidCallback onTap;
  final VoidCallback onAbonar;
  final VoidCallback onEliminar;

  const _DeudaCard({
    required this.deuda,
    required this.onTap,
    required this.onAbonar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              deuda.color.withOpacity(0.92),
              deuda.color.withOpacity(0.62),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: deuda.color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Acreedor + Badges + Acciones
            Row(
              children: [
                const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    deuda.acreedor.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (deuda.estaPagada)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('✅ SALDADA',
                        style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                if (!deuda.estaPagada) ...[
                  GestureDetector(
                    onTap: onAbonar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 15),
                          SizedBox(width: 3),
                          Text('Abonar',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                GestureDetector(
                  onTap: onEliminar,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white70, size: 16),
                  ),
                ),
              ],
            ),

            if (deuda.descripcion.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                deuda.descripcion,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // Saldo restante destacado
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fmt.format(deuda.saldoRestante),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        deuda.estaPagada ? 'Deuda completamente pagada' : 'Saldo pendiente por pagar',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Fecha límite de pago si existe
                if (deuda.fechaLimite != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Pagar antes de:',
                            style: TextStyle(color: Colors.white60, fontSize: 9)),
                        Text(dateFmt.format(deuda.fechaLimite!),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Barra de progreso de abonos
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: deuda.porcentajePagado,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  deuda.estaPagada ? const Color(0xFF69F0AE) : const Color(0xFFFFD54F),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),

            // Fila de montos (Total y Abonado)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${fmt.format(deuda.montoTotal)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  'Abonado: ${fmt.format(deuda.totalAbonado)} (${(deuda.porcentajePagado * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: deuda.estaPagada ? const Color(0xFF69F0AE) : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// [SHEET] _DetalleDeudaSheet — Historial de abonos con eliminación y registro
/// ============================================================================
class _DetalleDeudaSheet extends StatefulWidget {
  final DebtModel deuda;
  final VoidCallback onNuevoAbono;
  final VoidCallback onSyncCloud;

  const _DetalleDeudaSheet({
    required this.deuda,
    required this.onNuevoAbono,
    required this.onSyncCloud,
  });

  @override
  State<_DetalleDeudaSheet> createState() => _DetalleDeudaSheetState();
}

class _DetalleDeudaSheetState extends State<_DetalleDeudaSheet> {
  late DebtModel _deuda;

  @override
  void initState() {
    super.initState();
    _deuda = widget.deuda;
    DebtsService.notifier.addListener(_recargarDeuda);
    _recargarDeuda();
  }

  @override
  void dispose() {
    DebtsService.notifier.removeListener(_recargarDeuda);
    super.dispose();
  }

  Future<void> _recargarDeuda() async {
    final deudas = await DebtsService.getAll();
    final idx = deudas.indexWhere((d) => d.id == _deuda.id);
    if (idx != -1 && mounted) {
      setState(() => _deuda = deudas[idx]);
    }
  }

  Future<void> _eliminarAbono(DebtAbono abono) async {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Eliminar abono',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Eliminar el abono de ${fmt.format(abono.monto)}?\nEl saldo de la deuda aumentará.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.netflixRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Optimistic update
      setState(() {
        final abonos = _deuda.abonos.where((a) => a.id != abono.id).toList();
        _deuda = _deuda.copyWith(abonos: abonos);
      });
      await DebtsService.deleteAbono(_deuda.id, abono.id);
      widget.onSyncCloud();
    }
  }

  void _abrirModalAbono() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NuevoAbonoSheet(
        deuda: _deuda,
        onGuardar: (monto, nota) async {
          await DebtsService.addAbono(
            deudaId: _deuda.id,
            monto: monto,
            nota: nota,
          );
          widget.onSyncCloud();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy · hh:mm a');

    final abonosOrdenados = [..._deuda.abonos]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF18181E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle de arrastre
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(color: _deuda.color, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      _deuda.acreedor,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_deuda.estaPagada)
                    TextButton.icon(
                      onPressed: _abrirModalAbono,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Abonar'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF69F0AE),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Resumen de la deuda
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _colResumen('TOTAL', fmt.format(_deuda.montoTotal), AppTheme.textPrimary),
                        Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                        _colResumen(
                          '⏳ SALDO',
                          fmt.format(_deuda.saldoRestante),
                          _deuda.estaPagada ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80),
                        ),
                        Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                        _colResumen('✅ ABONADO', fmt.format(_deuda.totalAbonado), const Color(0xFF69F0AE)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _deuda.porcentajePagado,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _deuda.estaPagada ? const Color(0xFF69F0AE) : const Color(0xFFFFD54F),
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(color: AppTheme.borderSubtle, height: 1),

            // Lista de Abonos
            Expanded(
              child: abonosOrdenados.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.savings_outlined, color: AppTheme.textMuted, size: 40),
                        const SizedBox(height: 12),
                        const Text('Sin abonos registrados',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                        if (!_deuda.estaPagada)
                          TextButton(
                            onPressed: _abrirModalAbono,
                            child: const Text('Registrar primer abono →',
                                style: TextStyle(color: Color(0xFF69F0AE))),
                          ),
                      ]),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                      itemCount: abonosOrdenados.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final a = abonosOrdenados[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF69F0AE).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Color(0xFF69F0AE),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.nota.isNotEmpty ? a.nota : 'Abono a capital',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFmt.format(a.fecha),
                                      style: const TextStyle(
                                          color: AppTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '- ${fmt.format(a.monto)}',
                                    style: const TextStyle(
                                      color: Color(0xFF69F0AE),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('descontado',
                                      style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                                ],
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppTheme.netflixRed, size: 18),
                                tooltip: 'Eliminar abono',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                onPressed: () => _eliminarAbono(a),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colResumen(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

/// ============================================================================
/// [SHEET] _NuevaDeudaSheet — Formulario para registrar una nueva deuda
/// ============================================================================
class _NuevaDeudaSheet extends StatefulWidget {
  final Future<void> Function(
    String acreedor,
    double montoTotal, {
    String descripcion,
    DateTime? fechaLimite,
    Color? color,
  }) onGuardar;

  const _NuevaDeudaSheet({required this.onGuardar});

  @override
  State<_NuevaDeudaSheet> createState() => _NuevaDeudaSheetState();
}

class _NuevaDeudaSheetState extends State<_NuevaDeudaSheet> {
  final _acreedorCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _fechaLimite;
  Color _colorSeleccionado = const Color(0xFFE91E63);
  bool _guardando = false;

  static const _colores = [
    Color(0xFFE91E63), // Rosa
    Color(0xFF9C27B0), // Púrpura
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF1A73E8), // Azul
    Color(0xFF00897B), // Teal
    Color(0xFF43A047), // Verde
    Color(0xFFFB8C00), // Naranja
    Color(0xFFE53935), // Rojo
    Color(0xFF546E7A), // Blue Grey
  ];

  @override
  void dispose() {
    _acreedorCtrl.dispose();
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final acreedor = _acreedorCtrl.text.trim();
    if (acreedor.isEmpty) return;
    final monto =
        double.tryParse(_montoCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (monto == null || monto <= 0) return;

    setState(() => _guardando = true);
    try {
      await widget.onGuardar(
        acreedor,
        monto,
        descripcion: _descCtrl.text.trim(),
        fechaLimite: _fechaLimite,
        color: _colorSeleccionado,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppTheme.netflixRed),
        );
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaLimite ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _colorSeleccionado,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E1E24),
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaLimite = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF18181E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Nueva Deuda / Préstamo',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text(
                'Registra a quién o a qué entidad le debes dinero y su monto total.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Campo Acreedor
              _campoTexto(
                _acreedorCtrl,
                '¿A quién o a qué le debes? (Acreedor)',
                Icons.person_pin_rounded,
                TextInputType.text,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),

              // Campo Monto
              _campoTexto(
                _montoCtrl,
                'Monto total de la deuda (\$)',
                Icons.attach_money_rounded,
                TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 14),

              // Campo Concepto / Nota opcional
              _campoTexto(
                _descCtrl,
                'Concepto / Motivo (ej. Tarjeta, Repuestos, Moto)',
                Icons.notes_rounded,
                TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // Fecha límite opcional
              GestureDetector(
                onTap: _seleccionarFecha,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, color: AppTheme.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fechaLimite != null
                              ? 'Fecha límite: ${dateFmt.format(_fechaLimite!)}'
                              : 'Fecha límite de pago (Opcional)',
                          style: TextStyle(
                            color: _fechaLimite != null
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_fechaLimite != null)
                        GestureDetector(
                          onTap: () => setState(() => _fechaLimite = null),
                          child: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                        )
                      else
                        const Icon(Icons.calendar_today_outlined,
                            color: AppTheme.textMuted, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              const Text('Color de la tarjeta:',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Paleta de colores
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _colores.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final c = _colores[i];
                    final isSel = c.value == _colorSeleccionado.value;
                    return GestureDetector(
                      onTap: () => setState(() => _colorSeleccionado = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isSel ? 38 : 32,
                        height: isSel ? 38 : 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: isSel
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 26),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorSeleccionado,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('REGISTRAR DEUDA',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(
    TextEditingController ctrl,
    String label,
    IconData icon,
    TextInputType type, {
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        filled: true,
        fillColor: AppTheme.cardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.borderSubtle)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.borderSubtle)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _colorSeleccionado, width: 1.5)),
      ),
    );
  }
}

/// ============================================================================
/// [SHEET] _NuevoAbonoSheet — Formulario para abonar a una deuda
/// ============================================================================
class _NuevoAbonoSheet extends StatefulWidget {
  final DebtModel deuda;
  final Future<void> Function(double monto, String nota) onGuardar;

  const _NuevoAbonoSheet({required this.deuda, required this.onGuardar});

  @override
  State<_NuevoAbonoSheet> createState() => _NuevoAbonoSheetState();
}

class _NuevoAbonoSheetState extends State<_NuevoAbonoSheet> {
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto =
        double.tryParse(_montoCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (monto == null || monto <= 0) return;

    setState(() => _guardando = true);
    try {
      await widget.onGuardar(monto, _notaCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abonar: $e'), backgroundColor: AppTheme.netflixRed),
        );
      }
    }
  }

  void _fijarMonto(double valor) {
    setState(() {
      _montoCtrl.text = valor.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF18181E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: widget.deuda.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Abonar a ${widget.deuda.acreedor}',
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Saldo pendiente actual: ${fmt.format(widget.deuda.saldoRestante)}',
              style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Chips de sugerencia rápida
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.deuda.saldoRestante > 0)
                  ActionChip(
                    label: Text('Total (${fmt.format(widget.deuda.saldoRestante)})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFF69F0AE).withOpacity(0.15),
                    labelStyle: const TextStyle(color: Color(0xFF69F0AE)),
                    onPressed: () => _fijarMonto(widget.deuda.saldoRestante),
                  ),
                if (widget.deuda.saldoRestante > 0)
                  ActionChip(
                    label: Text('50% (${fmt.format(widget.deuda.saldoRestante / 2)})',
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.cardBg,
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    onPressed: () => _fijarMonto(widget.deuda.saldoRestante / 2),
                  ),
                ActionChip(
                  label: const Text('\$50.000', style: TextStyle(fontSize: 11)),
                  backgroundColor: AppTheme.cardBg,
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  onPressed: () => _fijarMonto(50000),
                ),
                ActionChip(
                  label: const Text('\$100.000', style: TextStyle(fontSize: 11)),
                  backgroundColor: AppTheme.cardBg,
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  onPressed: () => _fijarMonto(100000),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Campo Monto
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Monto a abonar (\$)',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFF69F0AE), size: 22),
                filled: true,
                fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderSubtle)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderSubtle)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF69F0AE), width: 1.5)),
              ),
            ),

            const SizedBox(height: 14),

            // Campo Nota
            TextField(
              controller: _notaCtrl,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Nota / Medio de pago (ej. Nequi, Quincena)',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.textMuted, size: 20),
                filled: true,
                fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderSubtle)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderSubtle)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.deuda.color, width: 1.5)),
              ),
            ),

            const SizedBox(height: 24),

            // Botón Abonar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('REGISTRAR ABONO',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
