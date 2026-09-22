import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/credit_card_model.dart';
import '../../services/cloud_sync_service.dart';
import '../../controllers/streaming_controller.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA] CreditCardsScreen — Control de Tarjetas de Crédito
/// ============================================================================
/// Módulo para gestionar compras con tarjetas de crédito y controlar
/// qué valores ya fueron subidos al bolsillo para pagar después.
/// ============================================================================
class CreditCardsScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final StreamingController? streamingController;

  const CreditCardsScreen({
    Key? key,
    required this.onOpenDrawer,
    this.streamingController,
  }) : super(key: key);

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {
  List<CreditCardModel> _tarjetas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    CreditCardsService.notifier.addListener(_recargar);
    _cargar();
  }

  @override
  void dispose() {
    CreditCardsService.notifier.removeListener(_recargar);
    super.dispose();
  }

  void _recargar() {
    if (mounted) _cargar();
  }

  Future<void> _cargar() async {
    final lista = await CreditCardsService.getAll();
    if (mounted) setState(() { _tarjetas = lista; _loading = false; });
  }

  void _syncCloud() {
    if (widget.streamingController != null) {
      CloudSyncService.triggerAutoSync(
        accounts: widget.streamingController!.accounts,
        creditCards: _tarjetas,
      );
    }
  }

  void _mostrarFormNuevaTarjeta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NuevaTarjetaSheet(
        onGuardar: (nombre, color,
            {int diaCorte = 0, int diaLimitePago = 0, double metaMensual = 0}) async {
          await CreditCardsService.add(
            nombre,
            color,
            diaCorte: diaCorte,
            diaLimitePago: diaLimitePago,
            metaMensual: metaMensual,
          );
          await _cargar();
          _syncCloud();
        },
      ),
    );
  }

  void _mostrarConfigCiclo(CreditCardModel tarjeta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarCicloSheet(
        tarjeta: tarjeta,
        onGuardar: (diaCorte, diaLimitePago, metaMensual) async {
          await CreditCardsService.updateCiclo(
            tarjeta.id,
            diaCorte: diaCorte,
            diaLimitePago: diaLimitePago,
            metaMensual: metaMensual,
          );
          await _cargar();
          _syncCloud();
        },
      ),
    );
  }

  Future<void> _eliminarTarjeta(CreditCardModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar tarjeta',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Eliminar la tarjeta "${t.nombre}"?\nSe perderán todos sus movimientos.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
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
      await CreditCardsService.delete(t.id);
      await _cargar();
      _syncCloud();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    // Totales globales
    final totalGlobal = _tarjetas.fold(0.0, (s, t) => s + t.totalComprado);
    final pendienteGlobal = _tarjetas.fold(0.0, (s, t) => s + t.totalPendienteBolsillo);

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormNuevaTarjeta,
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.credit_card, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
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
                        Text('Tarjetas de Crédito',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            )),
                        Text('Control de compras y bolsillo',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Resumen global ───────────────────────────────────────────────
            if (_tarjetas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A73E8).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResumenCol('TOTAL COMPRADO', fmt.format(totalGlobal), Colors.white),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildResumenCol(
                        '⏳ PENDIENTE',
                        fmt.format(pendienteGlobal),
                        pendienteGlobal > 0 ? const Color(0xFFFFD54F) : Colors.white60,
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildResumenCol(
                        '✅ AL BOLSILLO',
                        fmt.format(totalGlobal - pendienteGlobal),
                        const Color(0xFF69F0AE),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // ── Lista de tarjetas ────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.netflixRed, strokeWidth: 2))
                  : _tarjetas.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _tarjetas.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _TarjetaCard(
                            tarjeta: _tarjetas[i],
                            onEliminar: () => _eliminarTarjeta(_tarjetas[i]),
                            onAgregarMovimiento: () => _mostrarFormMovimiento(_tarjetas[i]),
                            onVerMovimientos: () => _abrirDetalleMovimientos(_tarjetas[i]),
                            onEditarCiclo: () => _mostrarConfigCiclo(_tarjetas[i]),
                            onSyncCloud: _syncCloud,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _mostrarFormMovimiento(CreditCardModel tarjeta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NuevoMovimientoSheet(
        tarjeta: tarjeta,
        onGuardar: (descripcion, monto) async {
          await CreditCardsService.addMovimiento(tarjeta.id, descripcion, monto);
          await _cargar();
          _syncCloud();
        },
      ),
    );
  }

  void _abrirDetalleMovimientos(CreditCardModel tarjeta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleMovimientosSheet(
        tarjeta: tarjeta,
        onToggleBolsillo: (movId) async {
          await CreditCardsService.toggleBolsillo(tarjeta.id, movId);
          await _cargar();
          _syncCloud();
        },
        onEliminarMovimiento: (movId) async {
          await CreditCardsService.deleteMovimiento(tarjeta.id, movId);
          await _cargar();
          _syncCloud();
        },
        onAgregarMovimiento: () {
          Navigator.pop(context);
          _mostrarFormMovimiento(tarjeta);
        },
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.credit_card_outlined,
                color: Color(0xFF1A73E8), size: 46),
          ),
          const SizedBox(height: 16),
          const Text('Sin tarjetas registradas',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Toca el botón + para agregar tu primera tarjeta',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ]),
      );
}

// ============================================================================
// Widget: Tarjeta Card — muestra ciclo actual + meta mensual
// ============================================================================
class _TarjetaCard extends StatelessWidget {
  final CreditCardModel tarjeta;
  final VoidCallback onEliminar;
  final VoidCallback onAgregarMovimiento;
  final VoidCallback onVerMovimientos;
  final VoidCallback? onEditarCiclo;
  final VoidCallback onSyncCloud;

  const _TarjetaCard({
    required this.tarjeta,
    required this.onEliminar,
    required this.onAgregarMovimiento,
    required this.onVerMovimientos,
    this.onEditarCiclo,
    required this.onSyncCloud,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final pendientes = tarjeta.movimientos.where((m) => !m.subioBolsillo).length;
    final tieneCiclo = tarjeta.diaCorte > 0;
    final montoMostrado = tieneCiclo ? tarjeta.totalCicloActual : tarjeta.totalComprado;
    final tieneMeta = tarjeta.metaMensual > 0;
    final metaCumplida = tarjeta.metaCumplida;

    // Días hasta el próximo corte
    int diasParaCorte = 0;
    if (tieneCiclo) {
      diasParaCorte = tarjeta.finCicloActual.difference(DateTime.now()).inDays + 1;
    }
    // Días hasta límite de pago
    int diasParaLimite = 0;
    if (tarjeta.diaLimitePago > 0 && tarjeta.fechaLimitePagoActual != null) {
      diasParaLimite = tarjeta.fechaLimitePagoActual!.difference(DateTime.now()).inDays + 1;
    }

    return GestureDetector(
      onTap: onVerMovimientos,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tarjeta.color.withOpacity(0.92),
              tarjeta.color.withOpacity(0.62),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: tarjeta.color.withOpacity(0.38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fila superior: nombre + acciones ──────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tarjeta.nombre.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Badge si la meta fue cumplida
                        if (metaCumplida)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF69F0AE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('✅ META',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onAgregarMovimiento,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Compra',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (onEditarCiclo != null)
                        GestureDetector(
                          onTap: onEditarCiclo,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      if (onEditarCiclo != null) const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onEliminar,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white70, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Monto principal del ciclo ──────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fmt.format(montoMostrado),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          tieneCiclo ? 'Compras del ciclo actual' : 'Total comprado (histórico)',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Chip de días para el corte
                  if (tieneCiclo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: diasParaCorte <= 5
                            ? Colors.red.withOpacity(0.35)
                            : Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$diasParaCorte',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          const Text('días corte',
                              style: TextStyle(color: Colors.white70, fontSize: 9)),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Barra de progreso hacia la meta mensual ────────────────
              if (tieneMeta) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meta sin cuota de manejo',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      '${(tarjeta.porcentajeMeta * 100).toStringAsFixed(0)}% de ${fmt.format(tarjeta.metaMensual)}',
                      style: TextStyle(
                        color: metaCumplida ? const Color(0xFF69F0AE) : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tarjeta.porcentajeMeta,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      metaCumplida ? const Color(0xFF69F0AE) : const Color(0xFFFFD54F),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── Fechas de corte y límite ───────────────────────────────
              if (tieneCiclo) ...[
                Row(
                  children: [
                    _buildFechaChip(
                      '✂️ Corte',
                      'día ${tarjeta.diaCorte}',
                      Colors.white.withOpacity(0.15),
                    ),
                    const SizedBox(width: 8),
                    if (tarjeta.diaLimitePago > 0)
                      _buildFechaChip(
                        '📅 Pago',
                        diasParaLimite > 0
                            ? 'día ${tarjeta.diaLimitePago} ($diasParaLimite días)'
                            : 'día ${tarjeta.diaLimitePago} ⚠️',
                        diasParaLimite <= 3 && diasParaLimite >= 0
                            ? Colors.orange.withOpacity(0.35)
                            : Colors.white.withOpacity(0.15),
                      ),
                    const Spacer(),
                    if (pendientes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pendientes pendiente${pendientes > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ] else if (pendientes > 0) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pendientes pendiente${pendientes > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Barra bolsillo (solo sin meta) ─────────────────────────
              if (!tieneMeta && tarjeta.totalComprado > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tarjeta.totalSubidoBolsillo / tarjeta.totalComprado,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF69F0AE)),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${((tarjeta.totalSubidoBolsillo / tarjeta.totalComprado) * 100).toStringAsFixed(0)}% subido al bolsillo',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFechaChip(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}


// ============================================================================
// Sheet: Detalle de movimientos de una tarjeta
// ============================================================================
class _DetalleMovimientosSheet extends StatelessWidget {
  final CreditCardModel tarjeta;
  final Function(String movId) onToggleBolsillo;
  final Function(String movId) onEliminarMovimiento;
  final VoidCallback onAgregarMovimiento;

  const _DetalleMovimientosSheet({
    required this.tarjeta,
    required this.onToggleBolsillo,
    required this.onEliminarMovimiento,
    required this.onAgregarMovimiento,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');

    final movimientosOrdenados = [...tarjeta.movimientos]
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
            // Header con nombre tarjeta + botón cerrar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(color: tarjeta.color, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      tarjeta.nombre,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onAgregarMovimiento();
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1A73E8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Resumen rápido
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _colResumen('TOTAL', fmt.format(tarjeta.totalComprado), AppTheme.textPrimary),
                    Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                    _colResumen('⏳ PENDIENTE', fmt.format(tarjeta.totalPendienteBolsillo),
                        const Color(0xFFFFD54F)),
                    Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                    _colResumen('✅ BOLSILLO', fmt.format(tarjeta.totalSubidoBolsillo),
                        const Color(0xFF69F0AE)),
                  ],
                ),
              ),
            ),
            const Divider(color: AppTheme.borderSubtle, height: 1),
            // Lista de movimientos
            Expanded(
              child: movimientosOrdenados.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.receipt_long_outlined,
                            color: AppTheme.textMuted, size: 40),
                        const SizedBox(height: 12),
                        const Text('Sin movimientos',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onAgregarMovimiento();
                          },
                          child: const Text('Agregar primera compra →',
                              style: TextStyle(color: Color(0xFF1A73E8))),
                        ),
                      ]),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                      itemCount: movimientosOrdenados.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final m = movimientosOrdenados[i];
                        return Dismissible(
                          key: Key(m.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.netflixRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_outline, color: AppTheme.netflixRed),
                          ),
                          onDismissed: (_) => onEliminarMovimiento(m.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: m.subioBolsillo
                                  ? AppTheme.successGreen.withOpacity(0.07)
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: m.subioBolsillo
                                    ? AppTheme.successGreen.withOpacity(0.3)
                                    : AppTheme.borderSubtle,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Icono estado bolsillo
                                GestureDetector(
                                  onTap: () => onToggleBolsillo(m.id),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: m.subioBolsillo
                                          ? AppTheme.successGreen.withOpacity(0.2)
                                          : AppTheme.cardElevated,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      m.subioBolsillo
                                          ? Icons.account_balance_wallet_rounded
                                          : Icons.account_balance_wallet_outlined,
                                      color: m.subioBolsillo
                                          ? AppTheme.successGreen
                                          : AppTheme.textMuted,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Descripción y fecha
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.descripcion,
                                          style: TextStyle(
                                            color: m.subioBolsillo
                                                ? AppTheme.textSecondary
                                                : AppTheme.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            decoration: m.subioBolsillo
                                                ? TextDecoration.none
                                                : null,
                                          )),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFmt.format(m.fecha),
                                        style: const TextStyle(
                                            color: AppTheme.textMuted, fontSize: 11),
                                      ),
                                      if (m.subioBolsillo && m.fechaSubidaBolsillo != null)
                                        Text(
                                          '✅ Bolsillo: ${dateFmt.format(m.fechaSubidaBolsillo!)}',
                                          style: const TextStyle(
                                              color: AppTheme.successGreen, fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),
                                // Monto
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      fmt.format(m.monto),
                                      style: TextStyle(
                                        color: m.subioBolsillo
                                            ? AppTheme.textSecondary
                                            : AppTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => onToggleBolsillo(m.id),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: m.subioBolsillo
                                              ? AppTheme.successGreen.withOpacity(0.15)
                                              : const Color(0xFFFFD54F).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          m.subioBolsillo ? '✅ Subido' : '⏳ Pendiente',
                                          style: TextStyle(
                                            color: m.subioBolsillo
                                                ? AppTheme.successGreen
                                                : const Color(0xFFFFD54F),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

// ============================================================================
// Sheet: Nuevo movimiento / compra
// ============================================================================
class _NuevoMovimientoSheet extends StatefulWidget {
  final CreditCardModel tarjeta;
  final Future<void> Function(String descripcion, double monto) onGuardar;

  const _NuevoMovimientoSheet({required this.tarjeta, required this.onGuardar});

  @override
  State<_NuevoMovimientoSheet> createState() => _NuevoMovimientoSheetState();
}

class _NuevoMovimientoSheetState extends State<_NuevoMovimientoSheet> {
  final _descCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_descCtrl.text.trim().isEmpty || _montoCtrl.text.trim().isEmpty) return;
    final monto = double.tryParse(_montoCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (monto == null || monto <= 0) return;
    setState(() => _guardando = true);
    await widget.onGuardar(_descCtrl.text, monto);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF18181E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: widget.tarjeta.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nueva compra · ${widget.tarjeta.nombre}',
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Campo descripción
            _campo(_descCtrl, 'Descripción de la compra', Icons.shopping_bag_rounded,
                TextInputType.text),
            const SizedBox(height: 12),
            // Campo monto
            _campo(_montoCtrl, 'Monto (\$)', Icons.attach_money_rounded,
                TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _guardando
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('REGISTRAR COMPRA',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon,
      TextInputType type, {List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: type == TextInputType.text ? TextCapitalization.sentences : TextCapitalization.none,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted),
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
            borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5)),
      ),
    );
  }
}

// ============================================================================
// Sheet: Nueva tarjeta (nombre + color)
// ============================================================================
// Sheet: Nueva tarjeta (nombre + color + fechas de ciclo)
// ============================================================================
class _NuevaTarjetaSheet extends StatefulWidget {
  final Future<void> Function(
    String nombre,
    Color color, {
    int diaCorte,
    int diaLimitePago,
    double metaMensual,
  }) onGuardar;
  const _NuevaTarjetaSheet({required this.onGuardar});

  @override
  State<_NuevaTarjetaSheet> createState() => _NuevaTarjetaSheetState();
}

class _NuevaTarjetaSheetState extends State<_NuevaTarjetaSheet> {
  final _nombreCtrl = TextEditingController();
  final _metaCtrl = TextEditingController();
  Color _colorSeleccionado = const Color(0xFFE53935);
  bool _guardando = false;
  int _diaCorte = 0;
  int _diaLimitePago = 0;

  static const _colores = [
    Color(0xFFE53935),
    Color(0xFF1A73E8),
    Color(0xFF00897B),
    Color(0xFF7B1FA2),
    Color(0xFFF57C00),
    Color(0xFF00BCD4),
    Color(0xFF43A047),
    Color(0xFFAD1457),
    Color(0xFF5C6BC0),
    Color(0xFFFF8F00),
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _metaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    final meta = double.tryParse(
            _metaCtrl.text.replaceAll('.', '').replaceAll(',', '')) ??
        0;
    await widget.onGuardar(
      _nombreCtrl.text,
      _colorSeleccionado,
      diaCorte: _diaCorte,
      diaLimitePago: _diaLimitePago,
      metaMensual: meta,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Nueva Tarjeta',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              // Vista previa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_colorSeleccionado, _colorSeleccionado.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _nombreCtrl.text.isEmpty
                            ? 'Nombre de la tarjeta'
                            : _nombreCtrl.text.toUpperCase(),
                        style: TextStyle(
                          color: _nombreCtrl.text.isEmpty ? Colors.white54 : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_diaCorte > 0)
                      Text('Corte: día $_diaCorte',
                          style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campo nombre
              _campoTexto(_nombreCtrl, 'Nombre de la tarjeta',
                  Icons.label_outline_rounded, TextInputType.text,
                  onChange: (_) => setState(() {})),
              const SizedBox(height: 12),

              // Fechas de ciclo
              const Text('Ciclo de facturación:',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DiaSelectorField(
                      label: '✂️ Día de corte',
                      value: _diaCorte,
                      accentColor: _colorSeleccionado,
                      onChanged: (v) => setState(() => _diaCorte = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DiaSelectorField(
                      label: '📅 Límite de pago',
                      value: _diaLimitePago,
                      accentColor: _colorSeleccionado,
                      onChanged: (v) => setState(() => _diaLimitePago = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Meta mensual
              _campoTexto(_metaCtrl, 'Meta mínima mensual (\$) — opcional',
                  Icons.flag_rounded, TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 4),
              const Text(
                'Monto mínimo de compras por ciclo para evitar cuota de manejo',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 16),

              // Paleta de colores
              const Text('Color:',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colores.map((color) {
                  final sel = _colorSeleccionado.value == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => _colorSeleccionado = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: sel ? 38 : 32,
                      height: sel ? 38 : 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: sel ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow:
                            sel ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)] : null,
                      ),
                      child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
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
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('CREAR TARJETA',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    void Function(String)? onChange,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization:
          type == TextInputType.text ? TextCapitalization.words : TextCapitalization.none,
      inputFormatters: inputFormatters,
      onChanged: onChange,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        filled: true,
        fillColor: AppTheme.cardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderSubtle)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderSubtle)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _colorSeleccionado, width: 1.5)),
      ),
    );
  }
}

// ============================================================================
// Sheet: Editar configuración de ciclo de una tarjeta existente
// ============================================================================
class _EditarCicloSheet extends StatefulWidget {
  final CreditCardModel tarjeta;
  final Future<void> Function(int diaCorte, int diaLimitePago, double metaMensual) onGuardar;

  const _EditarCicloSheet({required this.tarjeta, required this.onGuardar});

  @override
  State<_EditarCicloSheet> createState() => _EditarCicloSheetState();
}

class _EditarCicloSheetState extends State<_EditarCicloSheet> {
  late int _diaCorte;
  late int _diaLimitePago;
  final _metaCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _diaCorte = widget.tarjeta.diaCorte;
    _diaLimitePago = widget.tarjeta.diaLimitePago;
    if (widget.tarjeta.metaMensual > 0) {
      _metaCtrl.text = widget.tarjeta.metaMensual.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _metaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final meta =
        double.tryParse(_metaCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    await widget.onGuardar(_diaCorte, _diaLimitePago, meta);
    if (mounted) Navigator.pop(context);
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                      color: widget.tarjeta.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Configurar ciclo · ${widget.tarjeta.nombre}',
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Estas fechas controlan el contador de compras del ciclo actual. Al pasar la fecha de corte, el contador vuelve a 0.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 20),

            // Vista previa del ciclo
            if (_diaCorte > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.tarjeta.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.tarjeta.color.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoCol('Inicio ciclo', _formatDia(widget.tarjeta.inicioCicloActual)),
                        _infoCol('Corte', 'día $_diaCorte de cada mes'),
                        if (_diaLimitePago > 0)
                          _infoCol('Límite pago', 'día $_diaLimitePago'),
                      ],
                    ),
                    if (widget.tarjeta.metaMensual > 0 || _metaCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(color: AppTheme.borderSubtle, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flag_rounded, color: AppTheme.warningAmber, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Meta: ${fmt.format(double.tryParse(_metaCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? widget.tarjeta.metaMensual)} por ciclo',
                            style: const TextStyle(
                                color: AppTheme.warningAmber, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Campos días
            Row(
              children: [
                Expanded(
                  child: _DiaSelectorField(
                    label: '✂️ Día de corte',
                    value: _diaCorte,
                    accentColor: widget.tarjeta.color,
                    onChanged: (v) => setState(() => _diaCorte = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DiaSelectorField(
                    label: '📅 Límite de pago',
                    value: _diaLimitePago,
                    accentColor: widget.tarjeta.color,
                    onChanged: (v) => setState(() => _diaLimitePago = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Meta mensual
            TextField(
              controller: _metaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Meta mínima mensual (\$)',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.flag_rounded, color: AppTheme.textMuted, size: 20),
                hintText: '0 = sin meta',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.tarjeta.color, width: 1.5)),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Compras mínimas del ciclo para no pagar cuota de manejo',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.tarjeta.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('GUARDAR CONFIGURACIÓN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w900)),
      ],
    );
  }

  String _formatDia(DateTime d) {
    return DateFormat('dd MMM', 'es').format(d);
  }
}

// ============================================================================
// Widget: Selector de día del mes (1-31)
// ============================================================================
class _DiaSelectorField extends StatelessWidget {
  final String label;
  final int value;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const _DiaSelectorField({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final dias = List.generate(31, (i) => i + 1);
        final result = await showModalBottomSheet<int>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _DiaPicker(
            dias: dias,
            seleccionado: value,
            accentColor: accentColor,
            label: label,
          ),
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value > 0 ? accentColor.withOpacity(0.5) : AppTheme.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value > 0 ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
              color: value > 0 ? accentColor : AppTheme.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Text(
                    value > 0 ? 'Día $value de cada mes' : 'Sin configurar',
                    style: TextStyle(
                      color: value > 0 ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: value > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Picker de día del mes (bottom sheet)
// ============================================================================
class _DiaPicker extends StatelessWidget {
  final List<int> dias;
  final int seleccionado;
  final Color accentColor;
  final String label;

  const _DiaPicker({
    required this.dias,
    required this.seleccionado,
    required this.accentColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: const BoxDecoration(
        color: Color(0xFF18181E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
                TextButton(
                  onPressed: () => Navigator.pop(context, 0),
                  child: const Text('Sin configurar',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.borderSubtle, height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: dias.length,
              itemBuilder: (_, i) {
                final dia = dias[i];
                final sel = dia == seleccionado;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, dia),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: sel ? accentColor : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: sel
                          ? null
                          : Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Center(
                      child: Text(
                        '$dia',
                        style: TextStyle(
                          color: sel ? Colors.white : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w900 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
