import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// [MODELO] DebtAbono — Abono o pago parcial realizado a una deuda
/// ============================================================================
class DebtAbono {
  final String id;
  final double monto;
  final DateTime fecha;
  final String nota;

  DebtAbono({
    required this.id,
    required this.monto,
    required this.fecha,
    this.nota = '',
  });

  DebtAbono copyWith({
    String? id,
    double? monto,
    DateTime? fecha,
    String? nota,
  }) {
    return DebtAbono(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'nota': nota,
    };
  }

  factory DebtAbono.fromMap(Map<String, dynamic> map) {
    return DebtAbono(
      id: map['id']?.toString() ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
      fecha: map['fecha'] != null
          ? (DateTime.tryParse(map['fecha']) ?? DateTime.now())
          : DateTime.now(),
      nota: map['nota']?.toString() ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());
  factory DebtAbono.fromJson(String source) => DebtAbono.fromMap(jsonDecode(source));
}

/// ============================================================================
/// [MODELO] DebtModel — Deuda registrada con acreedor, saldo y abonos
/// ============================================================================
class DebtModel {
  final String id;
  final String acreedor; // A quién o a qué le debo (ej. Banco, Nequi, Amigo, Tienda)
  final double montoTotal; // Monto inicial / total de la deuda
  final String descripcion; // Concepto o notas adicionales
  final DateTime fechaCreacion;
  final DateTime? fechaLimite; // Fecha máxima para pagar (opcional)
  final int colorValue; // Color temático de la tarjeta
  final List<DebtAbono> abonos; // Lista de abonos que van descontando la deuda

  DebtModel({
    required this.id,
    required this.acreedor,
    required this.montoTotal,
    this.descripcion = '',
    DateTime? fechaCreacion,
    this.fechaLimite,
    this.colorValue = 0xFFE91E63, // Rosa/Fucsia por defecto
    this.abonos = const [],
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Color get color => Color(colorValue);

  /// Suma de todos los abonos realizados
  double get totalAbonado =>
      abonos.fold(0.0, (sum, a) => sum + a.monto);

  /// Saldo pendiente real por pagar (va descontando con cada abono)
  double get saldoRestante {
    final saldo = montoTotal - totalAbonado;
    return saldo > 0 ? saldo : 0.0;
  }

  /// Porcentaje pagado (0.0 a 1.0)
  double get porcentajePagado {
    if (montoTotal <= 0) return 1.0;
    return (totalAbonado / montoTotal).clamp(0.0, 1.0);
  }

  /// ¿La deuda ya fue pagada en su totalidad?
  bool get estaPagada => saldoRestante <= 0;

  /// Días que faltan para la fecha límite de pago (null si no tiene fecha límite)
  int? get diasParaVencer {
    if (fechaLimite == null) return null;
    return fechaLimite!.difference(DateTime.now()).inDays;
  }

  DebtModel copyWith({
    String? id,
    String? acreedor,
    double? montoTotal,
    String? descripcion,
    DateTime? fechaCreacion,
    DateTime? fechaLimite,
    int? colorValue,
    List<DebtAbono>? abonos,
  }) {
    return DebtModel(
      id: id ?? this.id,
      acreedor: acreedor ?? this.acreedor,
      montoTotal: montoTotal ?? this.montoTotal,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      colorValue: colorValue ?? this.colorValue,
      abonos: abonos ?? this.abonos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'acreedor': acreedor,
      'montoTotal': montoTotal,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaLimite': fechaLimite?.toIso8601String(),
      'colorValue': colorValue,
      'abonos': abonos.map((a) => a.toMap()).toList(),
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id']?.toString() ?? '',
      acreedor: map['acreedor']?.toString() ?? '',
      montoTotal: (map['montoTotal'] as num?)?.toDouble() ?? 0.0,
      descripcion: map['descripcion']?.toString() ?? '',
      fechaCreacion: map['fechaCreacion'] != null
          ? (DateTime.tryParse(map['fechaCreacion']) ?? DateTime.now())
          : DateTime.now(),
      fechaLimite: map['fechaLimite'] != null
          ? DateTime.tryParse(map['fechaLimite'])
          : null,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFE91E63,
      abonos: (map['abonos'] as List<dynamic>?)
              ?.map((a) => DebtAbono.fromMap(Map<String, dynamic>.from(a)))
              .toList() ??
          [],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory DebtModel.fromJson(String source) => DebtModel.fromMap(jsonDecode(source));
}

/// ============================================================================
/// [SERVICIO] DebtsService — CRUD de deudas y abonos con persistencia local
/// ============================================================================
class DebtsService {
  static const _kKey = 'deudas_v1';
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  /// Carga todas las deudas registradas
  static Future<List<DebtModel>> getAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kKey) ?? [];
    return raw.map((e) => DebtModel.fromJson(e)).toList();
  }

  /// Guarda la lista completa de deudas y dispara el notifier reactivo
  static Future<void> save(List<DebtModel> deudas) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kKey, deudas.map((d) => d.toJson()).toList());
    notifier.value++;
  }

  /// Agrega una nueva deuda
  static Future<DebtModel> add({
    required String acreedor,
    required double montoTotal,
    String descripcion = '',
    DateTime? fechaLimite,
    Color color = const Color(0xFFE91E63),
  }) async {
    final deudas = await getAll();
    final nueva = DebtModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      acreedor: acreedor.trim(),
      montoTotal: montoTotal,
      descripcion: descripcion.trim(),
      fechaLimite: fechaLimite,
      colorValue: color.value,
      abonos: [],
    );
    deudas.add(nueva);
    await save(deudas);
    return nueva;
  }

  /// Actualiza datos básicos de una deuda
  static Future<void> update(DebtModel deuda) async {
    final deudas = await getAll();
    final idx = deudas.indexWhere((d) => d.id == deuda.id);
    if (idx != -1) {
      deudas[idx] = deuda;
      await save(deudas);
    }
  }

  /// Elimina una deuda
  static Future<void> delete(String id) async {
    final deudas = await getAll();
    deudas.removeWhere((d) => d.id == id);
    await save(deudas);
  }

  /// Registra un abono a una deuda (va descontando el saldo restante)
  static Future<DebtAbono?> addAbono({
    required String deudaId,
    required double monto,
    String nota = '',
  }) async {
    if (monto <= 0) return null;
    final deudas = await getAll();
    final idx = deudas.indexWhere((d) => d.id == deudaId);
    if (idx == -1) return null;

    final abono = DebtAbono(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      monto: monto,
      fecha: DateTime.now(),
      nota: nota.trim(),
    );

    final listaActualizada = [...deudas[idx].abonos, abono];
    deudas[idx] = deudas[idx].copyWith(abonos: listaActualizada);
    await save(deudas);
    return abono;
  }

  /// Elimina un abono específico de una deuda
  static Future<void> deleteAbono(String deudaId, String abonoId) async {
    final deudas = await getAll();
    final idx = deudas.indexWhere((d) => d.id == deudaId);
    if (idx == -1) return;

    final listaActualizada =
        deudas[idx].abonos.where((a) => a.id != abonoId).toList();
    deudas[idx] = deudas[idx].copyWith(abonos: listaActualizada);
    await save(deudas);
  }
}
