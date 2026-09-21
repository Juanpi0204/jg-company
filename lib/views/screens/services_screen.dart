import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/streaming_controller.dart';
import '../../models/streaming_account_model.dart';
import '../components/account_detail_sheet.dart';
import '../components/account_form_modal.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA / PANTALLA] ServicesScreen — Pantallas & Streaming
/// ============================================================================
/// Lista PLANA de todas las pantallas/clientes activos.
/// Cada fila es un cliente individual (no agrupado por correo).
/// La hamburguesa llama directamente al callback [onOpenDrawer] del Shell.
/// ============================================================================
class ServicesScreen extends StatefulWidget {
  final StreamingController controller;
  final VoidCallback onOpenDrawer;

  const ServicesScreen({
    Key? key,
    required this.controller,
    required this.onOpenDrawer,
  }) : super(key: key);

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirDetalle(StreamingAccountModel account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AccountDetailSheet(
        account: account,
        controller: widget.controller,
        onEdit: (acc) => _abrirFormulario(accountParaEditar: acc),
      ),
    );
  }

  void _abrirFormulario({StreamingAccountModel? accountParaEditar}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AccountFormModal(
        accountParaEditar: accountParaEditar,
        controller: widget.controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(
        locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        // Lista PLANA — cada pantalla/cliente es una fila
        final accounts = widget.controller.filteredAccounts;
        final totalPorVencer =
            widget.controller.accounts.where((a) => a.esPorVencer).length;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── HEADER ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Hamburguesa → usa callback del Shell (funciona siempre)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onOpenDrawer,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: const Icon(Icons.menu_rounded,
                                  color: AppTheme.textPrimary, size: 22),
                            ),
                          ),
                        ),

                        // Campana + Avatar
                        Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppTheme.borderSubtle),
                                  ),
                                  child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: AppTheme.textPrimary,
                                      size: 22),
                                ),
                                if (totalPorVencer > 0)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.netflixRed,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: AppTheme.redGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: AppTheme.redGlow,
                              ),
                              child: const Center(
                                child: Text(
                                  'JG',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── TÍTULO ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pantallas & Streaming',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gestión de clientes y pantallas activas',
                          style: TextStyle(
                            color: AppTheme.textMuted.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── BARRA DE BÚSQUEDA ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181F),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF262632)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: widget.controller.setSearchQuery,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'Buscar por cliente, perfil, correo o PIN...',
                          hintStyle: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 13),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 14, right: 10),
                            child: Icon(Icons.search_rounded,
                                color: AppTheme.netflixRed, size: 22),
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppTheme.textMuted, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    widget.controller.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── FILTROS DE CATEGORÍA ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCategoryCard(
                            'Todos', Icons.grid_view_rounded, 'TODOS'),
                        _buildCategoryCard(
                            'Netflix', Icons.movie_filter_rounded, 'NETFLIX PA'),
                        _buildCategoryCard(
                            'Prime', Icons.live_tv_rounded, 'PRIME VIDEO PA'),
                        _buildCategoryCard('Disney',
                            Icons.play_circle_fill_rounded, 'DISNEY+ PA'),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── ENCABEZADO SECCIÓN ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pantallas Activas',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${accounts.length} pantallas',
                          style: const TextStyle(
                            color: AppTheme.netflixRed,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── LISTA PLANA DE PANTALLAS ─────────────────────────────────
                if (accounts.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pantalla = accounts[index];
                          return _buildPantallaCard(
                              pantalla, formatoMoneda, index);
                        },
                        childCount: accounts.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _abrirFormulario(),
            backgroundColor: AppTheme.netflixRed,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('NUEVA PANTALLA',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        );
      },
    );
  }

  // ─── TARJETA INDIVIDUAL DE PANTALLA ────────────────────────────────────────
  Widget _buildPantallaCard(
    StreamingAccountModel pantalla,
    NumberFormat fmt,
    int index,
  ) {
    Color semColor;
    String semTexto;
    Color borderColor;

    if (pantalla.esVencida) {
      semColor = AppTheme.netflixRed;
      semTexto = '🔴 Vencida (${pantalla.diasRestantes.abs()}d)';
      borderColor = AppTheme.netflixRed.withOpacity(0.25);
    } else if (pantalla.esPorVencer) {
      semColor = AppTheme.warningAmber;
      semTexto = '🟡 Vence en ${pantalla.diasRestantes}d';
      borderColor = AppTheme.warningAmber.withOpacity(0.25);
    } else {
      semColor = AppTheme.successGreen;
      semTexto = '🟢 Activa (${pantalla.diasRestantes}d)';
      borderColor = AppTheme.borderSubtle;
    }

    final esNetflix =
        pantalla.servicio.toUpperCase().contains('NETFLIX');
    final colorServicio =
        esNetflix ? AppTheme.netflixRed : AppTheme.infoBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirDetalle(pantalla),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF18181E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              // Avatar del perfil (número/letra del perfil Netflix)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorServicio.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    pantalla.perfil.isNotEmpty
                        ? pantalla.perfil.substring(0, 1)
                        : '?',
                    style: TextStyle(
                      color: colorServicio,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Datos del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pantalla.cliente.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pantalla.pin.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF262632),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PIN ${pantalla.pin}',
                              style: const TextStyle(
                                  color: AppTheme.warningAmber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${pantalla.servicio} • Perfil ${pantalla.perfil}',
                      style: TextStyle(
                        color: colorServicio.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          semTexto,
                          style: TextStyle(
                              color: semColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        const Text(' • ',
                            style: TextStyle(color: AppTheme.textMuted)),
                        Text(
                          '+${fmt.format(pantalla.ganancia)}',
                          style: const TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botones de acción
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Color(0xFF25D366), size: 18),
                    onPressed: () =>
                        widget.controller.sendWhatsApp(pantalla),
                    tooltip: 'Enviar credenciales por WhatsApp',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textMuted, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TARJETAS DE CATEGORÍA ──────────────────────────────────────────────────
  Widget _buildCategoryCard(
      String label, IconData icon, String filterValue) {
    final isSelected = widget.controller.serviceFilter == filterValue ||
        (filterValue == 'TODOS' &&
            widget.controller.serviceFilter == 'TODOS');

    return GestureDetector(
      onTap: () => widget.controller.setServiceFilter(filterValue),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.netflixRed
                  : const Color(0xFF18181F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.netflixRed
                    : const Color(0xFF282834),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.netflixRed.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
              fontSize: 11,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.tv_off_rounded,
              size: 54, color: AppTheme.textMuted.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text(
            'No hay pantallas en esta categoría',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca "Todos" o agrega una nueva pantalla',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
