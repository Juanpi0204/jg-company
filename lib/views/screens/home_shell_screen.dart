import 'package:flutter/material.dart';
import '../../controllers/streaming_controller.dart';
import '../../models/app_settings.dart';
import '../../services/cloud_sync_service.dart';
import '../theme/app_theme.dart';
import '../screens/main_dashboard_screen.dart';
import '../screens/services_screen.dart';
import '../screens/moto_screen.dart';
import '../screens/security_screen.dart';
import '../screens/clients_screen.dart';

/// ============================================================================
/// [VISTA / SHELL] HomeShellScreen
/// ============================================================================
/// Shell principal de la app. Gestiona la navegación y el ciclo de vida:
/// - Auto-sync al detectar cambios en cuentas de streaming
/// - Auto-sync en la nube antes de que la app se pause o cierre
/// ============================================================================
class HomeShellScreen extends StatefulWidget {
  final StreamingController streamingController;

  const HomeShellScreen({Key? key, required this.streamingController})
      : super(key: key);

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  String _nombreUsuario = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppSettings.getNombre().then((n) { if (mounted) setState(() => _nombreUsuario = n); });

    // Auto-sync reactivo cuando se agrega o edita una pantalla
    widget.streamingController.addListener(_onStreamingChanged);

    // Cargar automáticamente datos de MongoDB Atlas al abrir la app
    CloudSyncService.downloadFromCloud().then((data) {
      if (data != null && mounted) {
        widget.streamingController.init();
      }
    });
  }

  void _onStreamingChanged() {
    CloudSyncService.triggerAutoSync(
      accounts: widget.streamingController.accounts,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Guardar en MongoDB Atlas antes de que el usuario cierre o pause la app
      CloudSyncService.syncToCloud(
        accounts: widget.streamingController.accounts,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.streamingController.removeListener(_onStreamingChanged);
    super.dispose();
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
    // Cerrar el drawer si está abierto
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MainDashboardScreen(
        streamingController: widget.streamingController,
        onOpenStreaming: () => _navigateTo(1),
        onOpenMoto: () => _navigateTo(2),
        onOpenSecurity: () => _navigateTo(3),
        onOpenClients: () => _navigateTo(4),
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      ServicesScreen(
        controller: widget.streamingController,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      MotoScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      SecurityScreen(
        streamingController: widget.streamingController,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      ClientsScreen(
        streamingController: widget.streamingController,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: _buildDrawer(),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DRAWER LATERAL
  // ─────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    final items = [
      _DrawerItem(0, Icons.home_rounded, 'Inicio / Dashboard'),
      _DrawerItem(1, Icons.tv_rounded, 'Pantallas & Streaming'),
      _DrawerItem(4, Icons.people_rounded, 'Clientes'),
      _DrawerItem(2, Icons.two_wheeler_rounded, 'Control Moto & Aceite'),
      _DrawerItem(3, Icons.shield_rounded, 'Seguridad & Face ID'),
    ];

    return Drawer(
      backgroundColor: const Color(0xFF141418),
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppTheme.redGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.redGlow,
                    ),
                    child: const Center(
                      child: Text(
                        'JG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nombreUsuario.isEmpty ? 'Mi Perfil' : _nombreUsuario,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'JG COMPANY S.A.S',
                          style: TextStyle(
                            color: AppTheme.netflixRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF24242E), height: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 12),

            // Items de navegación
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: items
                    .map((item) => _buildDrawerTile(item))
                    .toList(),
              ),
            ),

            // Pie
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF24242E), width: 1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: AppTheme.successGreen, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Versión iOS Pro 1.0',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(_DrawerItem item) {
    final bool isSelected = _currentIndex == item.index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateTo(item.index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? Colors.black : AppTheme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final navItems = [
      _NavItem(Icons.home_rounded, 'Inicio'),
      _NavItem(Icons.tv_rounded, 'Streaming'),
      _NavItem(Icons.two_wheeler_rounded, 'Moto'),
      _NavItem(Icons.shield_rounded, 'Seguridad'),
      _NavItem(Icons.people_rounded, 'Clientes'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (i) {
              final item = navItems[i];
              final isSelected = _currentIndex == i;
              return GestureDetector(
                onTap: () => _navigateTo(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.netflixRed.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? AppTheme.netflixRed : AppTheme.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  final int index;
  final IconData icon;
  final String label;
  const _DrawerItem(this.index, this.icon, this.label);
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
