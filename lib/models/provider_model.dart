import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// [MODELO] ProviderModel — Proveedor de servicios de streaming
/// ============================================================================
/// Permite almacenar los datos de cada proveedor mayorista:
/// - Nombre (ej. DIGITAL HOUSE, S.G.R STREAMING, PUNTACANA, DISPONIBLES ALI)
/// - Teléfono de soporte técnico (WhatsApp para reportar caídas o fallas)
/// - Notas u observaciones
/// ============================================================================
class ProviderModel {
  final String id;
  final String nombre;
  final String telefono;
  final String notas;
  final DateTime fechaCreacion;

  ProviderModel({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.notas = '',
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'notas': notas,
        'fechaCreacion': fechaCreacion.toIso8601String(),
      };

  factory ProviderModel.fromMap(Map<String, dynamic> map) => ProviderModel(
        id: map['id'] ?? '',
        nombre: map['nombre'] ?? '',
        telefono: map['telefono'] ?? '',
        notas: map['notas'] ?? '',
        fechaCreacion: map['fechaCreacion'] != null
            ? DateTime.parse(map['fechaCreacion'])
            : DateTime.now(),
      );

  String toJson() => json.encode(toMap());
  factory ProviderModel.fromJson(String source) =>
      ProviderModel.fromMap(json.decode(source));

  ProviderModel copyWith({
    String? nombre,
    String? telefono,
    String? notas,
  }) =>
      ProviderModel(
        id: id,
        nombre: nombre ?? this.nombre,
        telefono: telefono ?? this.telefono,
        notas: notas ?? this.notas,
        fechaCreacion: fechaCreacion,
      );
}

/// ============================================================================
/// [SERVICIO] ProvidersService — Persistencia de proveedores
/// ============================================================================
class ProvidersService {
  static const _kKey = 'proveedores_v1';
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  // Proveedores sugeridos predeterminados
  static final List<ProviderModel> defaultProviders = [
    ProviderModel(
      id: 'prov_digital_house',
      nombre: 'DIGITAL HOUSE',
      telefono: '',
      notas: 'Proveedor principal de Netflix y Max',
    ),
    ProviderModel(
      id: 'prov_sgr_streaming',
      nombre: 'S.G.R STREAMING',
      telefono: '',
      notas: 'Proveedor de Disney+, Star+ y Prime Video',
    ),
    ProviderModel(
      id: 'prov_puntacana',
      nombre: 'PUNTACANA',
      telefono: '',
      notas: 'Proveedor de pantallas familiares',
    ),
    ProviderModel(
      id: 'prov_disponibles_ali',
      nombre: 'DISPONIBLES ALI',
      telefono: '',
      notas: 'Proveedor de Crunchyroll y Spotify',
    ),
  ];

  /// Obtiene todos los proveedores guardados; si no hay, inicializa con los predeterminados
  static Future<List<ProviderModel>> getAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kKey);
    if (raw == null || raw.isEmpty) {
      await save(defaultProviders);
      return List<ProviderModel>.from(defaultProviders)
        ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    }
    return raw.map((e) => ProviderModel.fromJson(e)).toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }

  static Future<void> save(List<ProviderModel> proveedores) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kKey, proveedores.map((c) => c.toJson()).toList());
    notifier.value++;
  }

  static Future<ProviderModel> add(
    String nombre,
    String telefono, {
    String notas = '',
  }) async {
    final proveedores = await getAll();
    final nuevo = ProviderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre.trim().toUpperCase(),
      telefono: telefono.trim(),
      notas: notas.trim(),
    );
    proveedores.add(nuevo);
    await save(proveedores);
    return nuevo;
  }

  static Future<void> update(ProviderModel proveedor) async {
    final proveedores = await getAll();
    final idx = proveedores.indexWhere((p) => p.id == proveedor.id);
    if (idx != -1) {
      proveedores[idx] = proveedor;
      await save(proveedores);
    }
  }

  static Future<void> delete(String id) async {
    final proveedores = await getAll();
    proveedores.removeWhere((p) => p.id == id);
    await save(proveedores);
  }

  /// Busca un proveedor por su nombre exacto o similar
  static Future<ProviderModel?> findByNombre(String nombre) async {
    final proveedores = await getAll();
    final n = nombre.trim().toLowerCase();
    final idx = proveedores.indexWhere((p) => p.nombre.toLowerCase() == n);
    if (idx != -1) return proveedores[idx];
    return null;
  }

  /// Devuelve el teléfono de soporte de un proveedor, si existe
  static Future<String> getTelefonoSoporte(String nombre) async {
    final p = await findByNombre(nombre);
    return p?.telefono ?? '';
  }
}
