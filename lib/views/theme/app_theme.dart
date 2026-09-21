import 'package:flutter/material.dart';

/// ============================================================================
/// [VISTA / TEMA] AppTheme
/// ============================================================================
/// Define la paleta de colores y estilos visuales de la aplicación:
/// - Fondo: Negro Obsidiana / Carbón (#0B0B0D)
/// - Tarjetas: Gris Oscuro Premium (#16161A y #1E1E24)
/// - Primario: Rojo Netflix (#E50914) con degradados
/// - Acentos: Verde Esmeralda (#10B981) para PAGO y Ámbar (#F59E0B) para PENDIENTE
/// - Tipografía: Blanco (#FFFFFF) y Grises de alto contraste
/// ============================================================================
class AppTheme {
  // Paleta de Colores
  static const Color background = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF141418);
  static const Color cardBg = Color(0xFF1C1C22);
  static const Color cardElevated = Color(0xFF24242C);
  
  static const Color netflixRed = Color(0xFFE50914);
  static const Color netflixDarkRed = Color(0xFFB81D24);
  
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  
  static const Color borderLight = Color(0xFF2E2E38);
  static const Color borderSubtle = Color(0xFF23232C);

  // Gradientes
  static const LinearGradient redGradient = LinearGradient(
    colors: [netflixRed, netflixDarkRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF202028), Color(0xFF17171C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profitGradient = LinearGradient(
    colors: [Color(0xFF065F46), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sombras
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> redGlow = [
    BoxShadow(
      color: netflixRed.withOpacity(0.35),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ThemeData para MaterialApp
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: netflixRed,
      colorScheme: const ColorScheme.dark(
        primary: netflixRed,
        secondary: successGreen,
        surface: surface,
        background: background,
        error: netflixRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: borderSubtle, width: 1),
        ),
      ),
    );
  }
}
