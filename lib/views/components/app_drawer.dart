import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [WIDGET / VISTA] AppDrawer (Menú Lateral Estilo UI de Referencia)
/// ============================================================================
/// Menú lateral moderno y curvado inspirado en la maqueta:
/// - Avatar y datos del administrador ("Juan - JG Company S.A.S")
/// - Indicadores en píldora activa redondeada
/// - Accesos limpios a:
///   1. Pantallas & Streaming
///   2. Mi Moto & Aceite
///   3. Ganancias & Reportes
///   4. Clientes & Contactos
///   5. Seguridad & Face ID
///   6. Respaldo de Base de Datos
/// ============================================================================
class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            // 1. Cabecera del Usuario / Administrador
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Juan Camilo',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
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

            const Divider(color: Color(0xFF24242E), height: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 16),

            // 2. Lista de Elementos del Menú con Estilo de Píldora Activa
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _buildDrawerItem(
                    index: 0,
                    icon: Icons.tv_rounded,
                    title: 'Pantallas & Streaming',
                    context: context,
                  ),
                  _buildDrawerItem(
                    index: 1,
                    icon: Icons.two_wheeler_rounded,
                    title: 'Control Moto & Aceite',
                    context: context,
                  ),
                  _buildDrawerItem(
                    index: 2,
                    icon: Icons.trending_up_rounded,
                    title: 'Ganancias & Reportes',
                    context: context,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Divider(color: Color(0xFF24242E), height: 1),
                  ),

                  _buildActionItem(
                    icon: Icons.fingerprint_rounded,
                    title: 'Seguridad & Face ID',
                    subtitle: 'Protección biométrica',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seguridad biométrica activa'),
                          backgroundColor: AppTheme.netflixRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _buildActionItem(
                    icon: Icons.backup_rounded,
                    title: 'Copia de Seguridad',
                    subtitle: 'Exportar datos JSON',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Base de datos sincronizada localmente'),
                          backgroundColor: AppTheme.cardElevated,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 3. Pie de página del Menú
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

  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required String title,
    required BuildContext context,
  }) {
    final bool isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onItemSelected(index);
            Navigator.pop(context);
          },
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
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.black : AppTheme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
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

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: AppTheme.textMuted, size: 20),
      title: Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 16),
    );
  }
}
