import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/streaming_controller.dart';
import '../../controllers/reports_controller.dart';
import '../../models/streaming_account_model.dart';
import '../../models/app_settings.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA / PANTALLA] MainDashboardScreen — Panel Principal (Diseño Premium)
/// ============================================================================
class MainDashboardScreen extends StatelessWidget {
  final StreamingController streamingController;
  final VoidCallback onOpenStreaming;
  final VoidCallback onOpenMoto;
  final VoidCallback onOpenSecurity;
  final VoidCallback onOpenClients;
  final VoidCallback? onOpenProviders;
  final VoidCallback onOpenDrawer;

  const MainDashboardScreen({
    Key? key,
    required this.streamingController,
    required this.onOpenStreaming,
    required this.onOpenMoto,
    required this.onOpenSecurity,
    required this.onOpenClients,
    this.onOpenProviders,
    required this.onOpenDrawer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: streamingController,
      builder: (context, _) {
        final accounts = streamingController.accounts;
        final gananciaTotal = ReportsController.gananciaNeta(accounts);
        final activas = accounts.where((a) => !a.esVencida && !a.esPorVencer).length;
        final porVencer = accounts.where((a) => a.esPorVencer).length;
        final vencidas = accounts.where((a) => a.esVencida).length;

        final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── APP BAR CON DEGRADADO ────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroHeader(
                  gananciaTotal: gananciaTotal,
                  totalPantallas: accounts.length,
                  fmt: fmt,
                  onOpenDrawer: onOpenDrawer,
                ),
              ),

              // ── SEMÁFOROS EN PÍLDORAS ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      _StatPill(label: 'Activas', value: '$activas', color: AppTheme.successGreen, icon: Icons.circle),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Por vencer', value: '$porVencer', color: AppTheme.warningAmber, icon: Icons.circle),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Vencidas', value: '$vencidas', color: AppTheme.netflixRed, icon: Icons.circle),
                    ],
                  ),
                ),
              ),

              // ── TÍTULO MÓDULOS ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    'ACCESO RÁPIDO',
                    style: TextStyle(
                      color: AppTheme.textMuted.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),

              // ── CHIPS COMPACTOS DE MÓDULOS (2 FILAS DE 3) ────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _QuickChip(
                              icon: Icons.tv_rounded,
                              label: 'Streaming',
                              sublabel: '${accounts.length} pantallas',
                              onTap: onOpenStreaming,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickChip(
                              icon: Icons.people_rounded,
                              label: 'Clientes',
                              sublabel: 'Directorio',
                              onTap: onOpenClients,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickChip(
                              icon: Icons.two_wheeler_rounded,
                              label: 'Mi Moto',
                              sublabel: 'Aceite & km',
                              onTap: onOpenMoto,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickChip(
                              icon: Icons.shield_rounded,
                              label: 'Seguridad',
                              sublabel: 'Face ID & Perfil',
                              onTap: onOpenSecurity,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickChip(
                              icon: Icons.storefront_rounded,
                              label: 'Proveedores',
                              sublabel: 'Soporte WA',
                              onTap: onOpenProviders ?? () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickChip(
                              icon: Icons.calculate_rounded,
                              label: 'Conteo',
                              sublabel: 'Caja diaria',
                              onTap: () {},
                              isComingSoon: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── GRÁFICO DE RENTABILIDAD ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _RentabilidadSection(accounts: accounts, fmt: fmt),
                ),
              ),

              // ── POR VENCER (mini lista) ──────────────────────────────────
              if (porVencer > 0) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.warningAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'POR VENCER PRONTO',
                          style: TextStyle(
                            color: AppTheme.warningAmber.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lista = accounts
                            .where((a) => a.esPorVencer)
                            .toList()
                          ..sort((a, b) => a.diasRestantes.compareTo(b.diasRestantes));
                        final acc = lista[index];
                        return _VencimientoRow(
                          acc: acc,
                          onSendReminder: () => streamingController.sendRenewalReminderWhatsApp(acc),
                        );
                      },
                      childCount: accounts.where((a) => a.esPorVencer).length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO HEADER CON DEGRADADO
// ─────────────────────────────────────────────────────────────────────────────
class _HeroHeader extends StatefulWidget {
  final double gananciaTotal;
  final int totalPantallas;
  final NumberFormat fmt;
  final VoidCallback onOpenDrawer;

  const _HeroHeader({
    required this.gananciaTotal,
    required this.totalPantallas,
    required this.fmt,
    required this.onOpenDrawer,
  });

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader> {
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    final n = await AppSettings.getNombre();
    if (mounted) setState(() => _nombre = n);
  }

  void _editarNombre() {
    final ctrl = TextEditingController(text: _nombre);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: AppTheme.netflixRed, size: 20),
            SizedBox(width: 10),
            Text(
              'Cambiar mi nombre',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escribe el nombre con el que quieres identificarte en la app:',
              style: TextStyle(color: Color(0xFF9999AA), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Tu nombre',
                hintStyle: const TextStyle(color: Color(0xFF555566)),
                filled: true,
                fillColor: const Color(0xFF141418),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E2E38)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.netflixRed),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF888899))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.netflixRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final nuevo = ctrl.text.trim();
              if (nuevo.isNotEmpty) {
                await AppSettings.setNombre(nuevo);
                if (mounted) setState(() => _nombre = nuevo);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches';
    final nombre = _nombre.isEmpty ? '...' : _nombre;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A0D), Color(0xFF0E0E14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila: hamburguesa + avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onOpenDrawer,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.menu_rounded, color: Colors.white70, size: 20),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppTheme.redGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.redGlow,
                    ),
                    child: const Center(
                      child: Text('JG',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Saludo y nombre con opción de editar
              Text(
                greeting,
                style: const TextStyle(color: Color(0xFF888899), fontSize: 13),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: _editarNombre,
                child: Row(
                  children: [
                    Text(
                      '$nombre 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white54, size: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Tarjeta de ganancia dentro del header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A0E14), Color(0xFF1A0E1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.netflixRed.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GANANCIA NETA STREAMING',
                          style: TextStyle(
                            color: Color(0xFF888899),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.fmt.format(widget.gananciaTotal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.netflixRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.netflixRed.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tv_rounded, color: AppTheme.netflixRed, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                '${widget.totalPantallas} pantallas',
                                style: const TextStyle(
                                  color: AppTheme.netflixRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PÍLDORAS DE ESTADÍSTICAS (Diseño limpio y sobrio sin fondos tintados)
// ─────────────────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatPill({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF7E7E8F),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIP COMPACTO DE MÓDULO — Diseño monocromático sobrio y elegante
// ─────────────────────────────────────────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool isComingSoon;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono con fondo sutil gris/neutro
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: isComingSoon
                      ? const Color(0xFF444455)
                      : const Color(0xFFE2E2E8),
                  size: 16,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                style: TextStyle(
                  color: isComingSoon
                      ? const Color(0xFF555566)
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isComingSoon ? 'Próximamente' : sublabel,
                style: TextStyle(
                  color: isComingSoon
                      ? const Color(0xFF3B3B48)
                      : const Color(0xFF7E7E8F),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECCIÓN RENTABILIDAD
// ─────────────────────────────────────────────────────────────────────────────
class _RentabilidadSection extends StatelessWidget {
  final List<StreamingAccountModel> accounts;
  final NumberFormat fmt;

  const _RentabilidadSection({required this.accounts, required this.fmt});

  @override
  Widget build(BuildContext context) {
    // Agrupar ganancias por servicio
    final Map<String, double> ganancias = {};
    final Map<String, int> conteos = {};
    for (var acc in accounts) {
      final key = acc.servicio.isNotEmpty ? acc.servicio : 'Sin servicio';
      ganancias[key] = (ganancias[key] ?? 0) + acc.ganancia;
      conteos[key] = (conteos[key] ?? 0) + 1;
    }

    if (ganancias.isEmpty) {
      ganancias['Netflix'] = 85000;
      ganancias['Prime Video'] = 42000;
      ganancias['Disney+'] = 28000;
      conteos['Netflix'] = 4;
      conteos['Prime Video'] = 2;
      conteos['Disney+'] = 1;
    }

    final entries = ganancias.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.map((e) => e.value).reduce(math.max).clamp(1.0, double.infinity);
    final totalGanancia = ganancias.values.fold(0.0, (a, b) => a + b);

    final barColors = [
      AppTheme.netflixRed,
      AppTheme.warningAmber,
      const Color(0xFF7C83FD),
      AppTheme.successGreen,
      AppTheme.infoBlue,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado sección
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RENTABILIDAD',
              style: TextStyle(
                color: AppTheme.textMuted.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            Text(
              fmt.format(totalGanancia),
              style: const TextStyle(
                color: AppTheme.successGreen,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Contenedor del gráfico
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141419),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF202028)),
          ),
          child: Column(
            children: [
              ...entries.take(5).toList().asMap().entries.map((e) {
                final i = e.key;
                final entry = e.value;
                final ratio = (entry.value / maxVal).clamp(0.0, 1.0);
                final pct = totalGanancia > 0
                    ? (entry.value / totalGanancia * 100).toStringAsFixed(0)
                    : '0';
                final color = barColors[i % barColors.length];
                final count = conteos[entry.key] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: Color(0xFFAAAAAA),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '$count cliente${count != 1 ? 's' : ''}',
                            style: const TextStyle(color: Color(0xFF555566), fontSize: 10),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            fmt.format(entry.value),
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$pct%',
                              style: const TextStyle(
                                color: Color(0xFF555566),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: Duration(milliseconds: 700 + i * 120),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Stack(
                            children: [
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252530),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: value,
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 6,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILA DE CUENTA POR VENCER
// ─────────────────────────────────────────────────────────────────────────────
class _VencimientoRow extends StatelessWidget {
  final StreamingAccountModel acc;
  final VoidCallback onSendReminder;

  const _VencimientoRow({required this.acc, required this.onSendReminder});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningAmber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.schedule_rounded, color: AppTheme.warningAmber, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc.cliente.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${acc.servicio} · Perfil ${acc.perfil}',
                  style: const TextStyle(color: Color(0xFF666677), fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${acc.diasRestantes}d',
              style: const TextStyle(
                color: AppTheme.warningAmber,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSendReminder,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active_rounded, color: Color(0xFF25D366), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Avisar',
                      style: TextStyle(
                        color: Color(0xFF25D366),
                        fontSize: 11,
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
    );
  }
}
