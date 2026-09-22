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

  /// Día del mes en que cierra el ciclo (fecha de corte)
  /// Ej: 15 → el corte es el día 15 de cada mes
  final int diaCorte;

  /// Día del mes límite para pagar la factura
  final int diaLimitePago;

  /// Meta mensual mínima de compras para no pagar cuota de manejo
  /// 0 = sin meta configurada
  final double metaMensual;

  CreditCardModel({
    required this.id,
    required this.nombre,
    required this.color,
    List<CreditCardMovement>? movimientos,
    DateTime? fechaCreacion,
    this.diaCorte = 0,
    this.diaLimitePago = 0,
    this.metaMensual = 0,
  })  : movimientos = movimientos ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Total comprado (suma de TODOS los movimientos, histórico)
  double get totalComprado =>
      movimientos.fold(0.0, (sum, m) => sum + m.monto);

  /// Total pendiente de subir al bolsillo (todos los movimientos)
  double get totalPendienteBolsillo => movimientos
      .where((m) => !m.subioBolsillo)
      .fold(0.0, (sum, m) => sum + m.monto);

  /// Total ya subido al bolsillo
  double get totalSubidoBolsillo => movimientos
      .where((m) => m.subioBolsillo)
      .fold(0.0, (sum, m) => sum + m.monto);

  static DateTime _safeDate(int year, int month, int day, [int hour = 0, int minute = 0, int second = 0]) {
    var y = year;
    var m = month;
    while (m < 1) {
      y -= 1;
      m += 12;
    }
    while (m > 12) {
      y += 1;
      m -= 12;
    }
    final lastDay = DateTime(y, m + 1, 0).day;
    final safeDay = day.clamp(1, lastDay);
    return DateTime(y, m, safeDay, hour, minute, second);
  }

  /// Calcula la fecha de inicio del ciclo actual basado en el día de corte
  /// Si diaCorte = 15 y hoy es 20 de septiembre → ciclo inició el 15 de septiembre
  /// Si hoy es 10 de septiembre → ciclo inició el 15 de agosto
  DateTime get inicioCicloActual {
    if (diaCorte == 0) return DateTime(2000); // Sin configurar → todos los movimientos
    final ahora = DateTime.now();
    if (ahora.day >= diaCorte) {
      // El corte ya pasó este mes → el ciclo inició el día de corte de este mes
      return _safeDate(ahora.year, ahora.month, diaCorte, 0, 0, 0);
    } else {
      // El corte no ha llegado este mes → el ciclo inició el día de corte del mes pasado
      return _safeDate(ahora.year, ahora.month - 1, diaCorte, 0, 0, 0);
    }
  }

  /// Fecha en que cierra el ciclo actual (próxima fecha de corte)
  DateTime get finCicloActual {
    if (diaCorte == 0) return DateTime(2099);
    final inicio = inicioCicloActual;
    return _safeDate(inicio.year, inicio.month + 1, diaCorte, 23, 59, 59);
  }

  /// Fecha límite de pago del ciclo actual
  DateTime? get fechaLimitePagoActual {
    if (diaLimitePago == 0) return null;
    final corte = finCicloActual;
    if (diaLimitePago > diaCorte) {
      return _safeDate(corte.year, corte.month, diaLimitePago, 23, 59, 59);
    } else {
      return _safeDate(corte.year, corte.month + 1, diaLimitePago, 23, 59, 59);
    }
  }

  /// Total de compras DENTRO del ciclo actual (se reinicia con cada corte)
  double get totalCicloActual {
    if (diaCorte == 0) return totalComprado;
    final inicio = inicioCicloActual;
    return movimientos
        .where((m) => m.fecha.isAfter(inicio) || m.fecha.isAtSameMomentAs(inicio))
        .fold(0.0, (sum, m) => sum + m.monto);
  }

  /// Porcentaje de la meta alcanzado en el ciclo actual (0.0 a 1.0)
  double get porcentajeMeta {
    if (metaMensual <= 0) return 0;
    return (totalCicloActual / metaMensual).clamp(0.0, 1.0);
  }

  /// Si la meta mensual ya fue cumplida
  bool get metaCumplida => metaMensual > 0 && totalCicloActual >= metaMensual;

  CreditCardModel copyWith({
    String? nombre,
    Color? color,
    List<CreditCardMovement>? movimientos,
    int? diaCorte,
    int? diaLimitePago,
    double? metaMensual,
  }) =>
      CreditCardModel(
        id: id,
        nombre: nombre ?? this.nombre,
        color: color ?? this.color,
        movimientos: movimientos ?? this.movimientos,
        fechaCreacion: fechaCreacion,
        diaCorte: diaCorte ?? this.diaCorte,
        diaLimitePago: diaLimitePago ?? this.diaLimitePago,
        metaMensual: metaMensual ?? this.metaMensual,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'colorValue': color.value,
        'movimientos': movimientos.map((m) => m.toMap()).toList(),
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'diaCorte': diaCorte,
        'diaLimitePago': diaLimitePago,
        'metaMensual': metaMensual,
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
        diaCorte: (map['diaCorte'] as num?)?.toInt() ?? 0,
        diaLimitePago: (map['diaLimitePago'] as num?)?.toInt() ?? 0,
        metaMensual: (map['metaMensual'] as num?)?.toDouble() ?? 0,
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

  static Future<CreditCardModel> add(
    String nombre,
    Color color, {
    int diaCorte = 0,
    int diaLimitePago = 0,
    double metaMensual = 0,
  }) async {
    final tarjetas = await getAll();
    final nueva = CreditCardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre.trim(),
      color: color,
      diaCorte: diaCorte,
      diaLimitePago: diaLimitePago,
      metaMensual: metaMensual,
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

  static Future<void> updateCiclo(
    String tarjetaId, {
    int? diaCorte,
    int? diaLimitePago,
    double? metaMensual,
  }) async {
    final tarjetas = await getAll();
    final idx = tarjetas.indexWhere((t) => t.id == tarjetaId);
    if (idx == -1) return;
    tarjetas[idx] = tarjetas[idx].copyWith(
      diaCorte: diaCorte,
      diaLimitePago: diaLimitePago,
      metaMensual: metaMensual,
    );
    await save(tarjetas);
  }

  static Future<void> delete(String id) async {
    final tarjetas = await getAll();
    tarjetas.removeWhere((t) => t.id == id);
    await save(tarjetas);
  }

  static const _kDescKey = 'tarjetas_descripciones_sugeridas_v1';

  static const List<String> defaultSugerencias = [
    'Netflix',
    'Disney+',
    'Prime Video',
    'Max',
    'Spotify',
    'Paramount+',
    'Crunchyroll',
    'Hosting / Dominio',
    'Combos',
  ];

  static Future<List<String>> getDescripcionesSugeridas() async {
    final p = await SharedPreferences.getInstance();
    final guardadas = p.getStringList(_kDescKey);
    final resultado = <String>{};

    if (guardadas != null && guardadas.isNotEmpty) {
      resultado.addAll(guardadas);
    }

    // Agregar también cualquier descripción de movimientos existentes
    final tarjetas = await getAll();
    for (final t in tarjetas) {
      for (final m in t.movimientos) {
        if (m.descripcion.trim().isNotEmpty) {
          resultado.add(m.descripcion.trim());
        }
      }
    }

    // Si aún no hay suficientes, agregar predeterminadas
    for (final def in defaultSugerencias) {
      resultado.add(def);
    }

    return resultado.toList();
  }

  static Future<void> guardarDescripcionSugerida(String desc) async {
    final clean = desc.trim();
    if (clean.isEmpty) return;
    final actuales = await getDescripcionesSugeridas();
    final nuevaLista = [
      clean,
      ...actuales.where((d) => d.toLowerCase() != clean.toLowerCase())
    ];
    if (nuevaLista.length > 30) {
      nuevaLista.removeRange(30, nuevaLista.length);
    }
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kDescKey, nuevaLista);
  }

  static Future<void> addMovimiento(
    String tarjetaId,
    String descripcion,
    double monto,
  ) async {
    final tarjetas = await getAll();
    final idx = tarjetas.indexWhere((t) => t.id == tarjetaId);
    if (idx == -1) return;
    final cleanDesc = descripcion.trim();
    final movimiento = CreditCardMovement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descripcion: cleanDesc,
      monto: monto,
      fecha: DateTime.now(),
    );
    final movimientos = [...tarjetas[idx].movimientos, movimiento];
    tarjetas[idx] = tarjetas[idx].copyWith(movimientos: movimientos);
    await save(tarjetas);
    await guardarDescripcionSugerida(cleanDesc);
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
