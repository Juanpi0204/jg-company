import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [WIDGET / VISTA] BottomNavBar
/// ============================================================================
/// Barra de navegación inferior flotante con estilo moderno iOS:
/// - 4 pestañas:
///   1. Clientes (Lista de pantallas y clientes)
///   2. Reportes (Análisis de ganancias y rentabilidad)
///   3. Servicios (Inventario agrupado por Netflix, Prime, etc.)
///   4. Módulos (Moto, Préstamos y Respaldo)
/// ============================================================================
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.95),
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
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.tv_rounded, 'Pantallas & Streaming'),
              _buildNavItem(1, Icons.two_wheeler_rounded, 'Mi Moto'),
              _buildNavItem(2, Icons.trending_up_rounded, 'Ganancias'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.netflixRed.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.netflixRed : AppTheme.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
