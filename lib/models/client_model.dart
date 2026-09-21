import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// [MODELO] ClientModel — Cliente registrado en la app
/// ============================================================================
class ClientModel {
  final String id;
  final String nombre;
  final String telefono;
  final DateTime fechaCreacion;

  ClientModel({
    required this.id,
    required this.nombre,
    required this.telefono,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'fechaCreacion': fechaCreacion.toIso8601String(),
      };

  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
        id: map['id'] ?? '',
        nombre: map['nombre'] ?? '',
        telefono: map['telefono'] ?? '',
        fechaCreacion: map['fechaCreacion'] != null
            ? DateTime.parse(map['fechaCreacion'])
            : DateTime.now(),
      );

  String toJson() => json.encode(toMap());
  factory ClientModel.fromJson(String source) =>
      ClientModel.fromMap(json.decode(source));

  ClientModel copyWith({String? nombre, String? telefono}) => ClientModel(
        id: id,
        nombre: nombre ?? this.nombre,
        telefono: telefono ?? this.telefono,
        fechaCreacion: fechaCreacion,
      );
}

/// ============================================================================
/// [SERVICIO] ClientsService — Persistencia de clientes
/// ============================================================================
class ClientsService {
  static const _kKey = 'clientes_v1';
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static Future<List<ClientModel>> getAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kKey) ?? [];
    return raw.map((e) => ClientModel.fromJson(e)).toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }

  static Future<void> save(List<ClientModel> clientes) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kKey, clientes.map((c) => c.toJson()).toList());
    notifier.value++;
  }

  static Future<ClientModel> add(String nombre, String telefono) async {
    final clientes = await getAll();
    final nuevo = ClientModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre.trim(),
      telefono: telefono.trim(),
    );
    clientes.add(nuevo);
    await save(clientes);
    return nuevo;
  }

  static Future<void> update(ClientModel cliente) async {
    final clientes = await getAll();
    final idx = clientes.indexWhere((c) => c.id == cliente.id);
    if (idx != -1) {
      clientes[idx] = cliente;
      await save(clientes);
    }
  }

  static Future<void> delete(String id) async {
    final clientes = await getAll();
    clientes.removeWhere((c) => c.id == id);
    await save(clientes);
  }
}
