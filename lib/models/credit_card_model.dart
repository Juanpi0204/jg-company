import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// [MODELO] CreditCardMovement — Un movimiento / compra con tarjeta de crédito
/// ============================================================================
class CreditCardMovement {
  final String id;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final bool subioBolsillo; // ¿Ya subí el valor al bolsillo para pagar?
  final DateTime? fechaSubidaBolsillo;

  CreditCardMovement({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    this.subioBolsillo = false,
    this.fechaSubidaBolsillo,
  });

  CreditCardMovement copyWith({
    String? descripcion,
    double? monto,
    DateTime? fecha,
    bool? subioBolsillo,
    DateTime? fechaSubidaBolsillo,
  }) =>
      CreditCardMovement(
        id: id,
        descripcion: descripcion ?? this.descripcion,
        monto: monto ?? this.monto,
        fecha: fecha ?? this.fecha,
        subioBolsillo: subioBolsillo ?? this.subioBolsillo,
        fechaSubidaBolsillo: fechaSubidaBolsillo ?? this.fechaSubidaBolsillo,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'descripcion': descripcion,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'subioBolsillo': subioBolsillo,
        'fechaSubidaBolsillo': fechaSubidaBolsillo?.toIso8601String(),
      };

  factory CreditCardMovement.fromMap(Map<String, dynamic> map) =>
      CreditCardMovement(
        id: map['id'] ?? '',
        descripcion: map['descripcion'] ?? '',
        monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
        fecha: map['fecha'] != null
            ? DateTime.parse(map['fecha'])
            : DateTime.now(),
        subioBolsillo: map['subioBolsillo'] == true,
        fechaSubidaBolsillo: map['fechaSubidaBolsillo'] != null
            ? DateTime.tryParse(map['fechaSubidaBolsillo'])
            : null,
      );
}

/// ============================================================================
/// [MODELO] CreditCardModel — Tarjeta de crédito con historial de movimientos
/// ============================================================================
class CreditCardModel {
  final String id;
  final String nombre;
  final Color color;
  final List<CreditCardMovement> movimientos;
  final DateTime fechaCreacion;

  CreditCardModel({
    required this.id,
    required this.nombre,
    required this.color,
    List<CreditCardMovement>? movimientos,
    DateTime? fechaCreacion,
  })  : movimientos = movimientos ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Total comprado (suma de todos los movimientos)
  double get totalComprado =>
      movimientos.fold(0.0, (sum, m) => sum + m.monto);

  /// Total pendiente de subir al bolsillo
  double get totalPendienteBolsillo => movimientos
      .where((m) => !m.subioBolsillo)
      .fold(0.0, (sum, m) => sum + m.monto);

  /// Total ya subido al bolsillo
  double get totalSubidoBolsillo => movimientos
      .where((m) => m.subioBolsillo)
      .fold(0.0, (sum, m) => sum + m.monto);

  CreditCardModel copyWith({
    String? nombre,
    Color? color,
    List<CreditCardMovement>? movimientos,
  }) =>
      CreditCardModel(
        id: id,
        nombre: nombre ?? this.nombre,
        color: color ?? this.color,
        movimientos: movimientos ?? this.movimientos,
        fechaCreacion: fechaCreacion,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'colorValue': color.value,
        'movimientos': movimientos.map((m) => m.toMap()).toList(),
        'fechaCreacion': fechaCreacion.toIso8601String(),
      };

  factory CreditCardModel.fromMap(Map<String, dynamic> map) => CreditCardModel(
        id: map['id'] ?? '',
        nombre: map['nombre'] ?? '',
        color: Color(map['colorValue'] ?? 0xFFE53935),
        movimientos: (map['movimientos'] as List?)
                ?.map((m) =>
                    CreditCardMovement.fromMap(Map<String, dynamic>.from(m)))
                .toList() ??
            [],
        fechaCreacion: map['fechaCreacion'] != null
            ? DateTime.tryParse(map['fechaCreacion']) ?? DateTime.now()
            : DateTime.now(),
      );

  String toJson() => json.encode(toMap());
  factory CreditCardModel.fromJson(String source) =>
      CreditCardModel.fromMap(json.decode(source));
}

/// ============================================================================
/// [SERVICIO] CreditCardsService — CRUD de tarjetas de crédito
/// ============================================================================
class CreditCardsService {
  static const _kKey = 'tarjetas_credito_v1';
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static Future<List<CreditCardModel>> getAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kKey) ?? [];
    return raw.map((e) => CreditCardModel.fromJson(e)).toList();
  }

  static Future<void> save(List<CreditCardModel> tarjetas) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kKey, tarjetas.map((c) => c.toJson()).toList());
    notifier.value++;
  }

  static Future<CreditCardModel> add(String nombre, Color color) async {
    final tarjetas = await getAll();
    final nueva = CreditCardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre.trim(),
      color: color,
    );
    tarjetas.add(nueva);
    await save(tarjetas);
    return nueva;
  }

  static Future<void> update(CreditCardModel tarjeta) async {
    final tarjetas = await getAll();
    final idx = tarjetas.indexWhere((t) => t.id == tarjeta.id);
    if (idx != -1) {
      tarjetas[idx] = tarjeta;
      await save(tarjetas);
    }
  }

  static Future<void> delete(String id) async {
    final tarjetas = await getAll();
    tarjetas.removeWhere((t) => t.id == id);
    await save(tarjetas);
  }

  static Future<void> addMovimiento(
    String tarjetaId,
    String descripcion,
    double monto,
  ) async {
    final tarjetas = await getAll();
    final idx = tarjetas.indexWhere((t) => t.id == tarjetaId);
    if (idx == -1) return;
    final movimiento = CreditCardMovement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descripcion: descripcion.trim(),
      monto: monto,
      fecha: DateTime.now(),
    );
    final movimientos = [...tarjetas[idx].movimientos, movimiento];
    tarjetas[idx] = tarjetas[idx].copyWith(movimientos: movimientos);
    await save(tarjetas);
  }

  static Future<void> toggleBolsillo(
    String tarjetaId,
    String movimientoId,
  ) async {
    final tarjetas = await getAll();
    final idx = tarjetas.indexWhere((t) => t.id == tarjetaId);
    if (idx == -1) return;
    final movimientos = tarjetas[idx].movimientos.map((m) {
      if (m.id == movimientoId) {
        return m.copyWith(
          subioBolsillo: !m.subioBolsillo,
          fechaSubidaBolsillo:
              !m.subioBolsillo ? DateTime.now() : null,
        );
      }
      return m;
    }).toList();
    tarjetas[idx] = tarjetas[idx].copyWith(movimientos: movimientos);
    await save(tarjetas);
  }

  static Future<void> deleteMovimiento(
    String tarjetaId,
    String movimientoId,
  ) async {
    final tarjetas = await getAll();
    final idx = tarjetas.indexWhere((t) => t.id == tarjetaId);
    if (idx == -1) return;
    final movimientos = tarjetas[idx]
        .movimientos
        .where((m) => m.id != movimientoId)
        .toList();
    tarjetas[idx] = tarjetas[idx].copyWith(movimientos: movimientos);
    await save(tarjetas);
  }
}
