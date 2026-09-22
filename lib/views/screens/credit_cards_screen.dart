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
        onGuardar: (nombre, color) async {
          await CreditCardsService.add(nombre, color);
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
// Widget: Tarjeta Card
// ============================================================================
class _TarjetaCard extends StatelessWidget {
  final CreditCardModel tarjeta;
  final VoidCallback onEliminar;
  final VoidCallback onAgregarMovimiento;
  final VoidCallback onVerMovimientos;
  final VoidCallback onSyncCloud;

  const _TarjetaCard({
    required this.tarjeta,
    required this.onEliminar,
    required this.onAgregarMovimiento,
    required this.onVerMovimientos,
    required this.onSyncCloud,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final pendientes = tarjeta.movimientos.where((m) => !m.subioBolsillo).length;

    return GestureDetector(
      onTap: onVerMovimientos,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tarjeta.color.withOpacity(0.9),
              tarjeta.color.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: tarjeta.color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: nombre + acciones
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
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Botón agregar movimiento rápido
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
                      const SizedBox(width: 8),
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
              const SizedBox(height: 20),
              // Total comprado
              Text(
                fmt.format(tarjeta.totalComprado),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const Text(
                'Total comprado',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 14),
              // Fila estadísticas
              Row(
                children: [
                  _buildMiniStat('⏳ Pendiente', fmt.format(tarjeta.totalPendienteBolsillo),
                      const Color(0xFFFFD54F)),
                  const SizedBox(width: 16),
                  _buildMiniStat('✅ Al bolsillo', fmt.format(tarjeta.totalSubidoBolsillo),
                      const Color(0xFF69F0AE)),
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
              const SizedBox(height: 8),
              // Barra de progreso: % subido al bolsillo
              if (tarjeta.totalComprado > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tarjeta.totalSubidoBolsillo / tarjeta.totalComprado,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF69F0AE)),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
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

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
      ],
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
class _NuevaTarjetaSheet extends StatefulWidget {
  final Future<void> Function(String nombre, Color color) onGuardar;
  const _NuevaTarjetaSheet({required this.onGuardar});

  @override
  State<_NuevaTarjetaSheet> createState() => _NuevaTarjetaSheetState();
}

class _NuevaTarjetaSheetState extends State<_NuevaTarjetaSheet> {
  final _nombreCtrl = TextEditingController();
  Color _colorSeleccionado = const Color(0xFFE53935);
  bool _guardando = false;

  static const _colores = [
    Color(0xFFE53935), // Rojo
    Color(0xFF1A73E8), // Azul Google
    Color(0xFF00897B), // Verde teal
    Color(0xFF7B1FA2), // Morado
    Color(0xFFF57C00), // Naranja
    Color(0xFF00BCD4), // Cyan
    Color(0xFF43A047), // Verde
    Color(0xFFAD1457), // Rosa oscuro
    Color(0xFF5C6BC0), // Índigo
    Color(0xFFFF8F00), // Ámbar
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    await widget.onGuardar(_nombreCtrl.text, _colorSeleccionado);
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
            const SizedBox(height: 18),
            const Text('Nueva Tarjeta',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            // Vista previa de la tarjeta
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
                  Text(
                    _nombreCtrl.text.isEmpty ? 'Nombre de la tarjeta' : _nombreCtrl.text.toUpperCase(),
                    style: TextStyle(
                      color: _nombreCtrl.text.isEmpty ? Colors.white54 : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Campo nombre
            TextField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Nombre de la tarjeta',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.label_outline_rounded, color: AppTheme.textMuted, size: 20),
                hintText: 'Ej: Visa Bancolombia, Mastercard Nu...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
            ),
            const SizedBox(height: 16),
            const Text('Color de la tarjeta:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Paleta de colores
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colores.map((color) {
                final seleccionado = _colorSeleccionado.value == color.value;
                return GestureDetector(
                  onTap: () => setState(() => _colorSeleccionado = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: seleccionado ? 38 : 32,
                    height: seleccionado ? 38 : 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: seleccionado
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: seleccionado
                          ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)]
                          : null,
                    ),
                    child: seleccionado
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : null,
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
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('CREAR TARJETA',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
