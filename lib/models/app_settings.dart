import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// [SERVICIO] AppSettings — Configuración global de la app
/// ============================================================================
/// Guarda en SharedPreferences:
/// - Nombre del usuario (para el saludo en el dashboard)
/// - Precios por defecto por servicio (costo y venta)
/// ============================================================================
class AppSettings {
  // ── Claves ─────────────────────────────────────────────────────────────────
  static const _kNombre         = 'settings_nombre_usuario';
  static const _kPreciosCostos  = 'settings_precios_costos';
  static const _kPreciosVentas  = 'settings_precios_ventas';

  // ── Nombre del usuario ────────────────────────────────────────────────────
  static Future<String> getNombre() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kNombre) ?? 'Juan';
  }

  static Future<void> setNombre(String nombre) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kNombre, nombre.trim());
  }

  // ── Precios por servicio ──────────────────────────────────────────────────
  /// Retorna mapa de {servicio: costo}
  static Future<Map<String, double>> getCostos() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kPreciosCostos);
    if (raw == null) return _defaultCostos();
    try {
      final map = Map<String, dynamic>.from(
        Uri.splitQueryString(raw).map((k, v) => MapEntry(k, double.tryParse(v) ?? 0.0)),
      );
      final defaults = _defaultCostos();
      defaults.addAll(Map<String, double>.from(map));
      return defaults;
    } catch (_) {
      return _defaultCostos();
    }
  }

  static Future<Map<String, double>> getVentas() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kPreciosVentas);
    if (raw == null) return _defaultVentas();
    try {
      final map = Map<String, dynamic>.from(
        Uri.splitQueryString(raw).map((k, v) => MapEntry(k, double.tryParse(v) ?? 0.0)),
      );
      final defaults = _defaultVentas();
      defaults.addAll(Map<String, double>.from(map));
      return defaults;
    } catch (_) {
      return _defaultVentas();
    }
  }

  static Future<void> setCostos(Map<String, double> costos) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kPreciosCostos,
      costos.entries.map((e) => '${Uri.encodeComponent(e.key)}=${e.value}').join('&'),
    );
  }

  static Future<void> setVentas(Map<String, double> ventas) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kPreciosVentas,
      ventas.entries.map((e) => '${Uri.encodeComponent(e.key)}=${e.value}').join('&'),
    );
  }

  /// Devuelve el precio de venta guardado para un servicio dado
  static Future<double> getVentaParaServicio(String servicio) async {
    final ventas = await getVentas();
    return ventas[servicio] ?? 14000;
  }

  /// Devuelve el costo guardado para un servicio dado
  static Future<double> getCostoParaServicio(String servicio) async {
    final costos = await getCostos();
    return costos[servicio] ?? 11000;
  }

  // ── Valores por defecto ───────────────────────────────────────────────────
  static Map<String, double> _defaultCostos() => {
        'NETFLIX PA':       11000,
        'PRIME VIDEO PA':   5000,
        'DISNEY+ PA':       5000,
        'MAX PA':           5000,
        'SPOTIFY FAMILIAR': 5000,
        'CRUNCHYROLL':      5000,
      };

  static Map<String, double> _defaultVentas() => {
        'NETFLIX PA':       14000,
        'PRIME VIDEO PA':   10000,
        'DISNEY+ PA':       10000,
        'MAX PA':           10000,
        'SPOTIFY FAMILIAR': 10000,
        'CRUNCHYROLL':      10000,
      };

  static List<String> get servicios => [
        'NETFLIX PA',
        'PRIME VIDEO PA',
        'DISNEY+ PA',
        'MAX PA',
        'SPOTIFY FAMILIAR',
        'CRUNCHYROLL',
      ];
}
