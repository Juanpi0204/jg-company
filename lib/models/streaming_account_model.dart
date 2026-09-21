import 'dart:convert';

/// ============================================================================
/// [MODELO] StreamingAccountModel
/// ============================================================================
/// Este modelo representa una pantalla o cuenta de streaming vendida a un cliente.
/// Mapea exactamente las columnas de la hoja de Excel de JG COMPANY S.A.S:
/// - Proveedor (ej. DIGITAL HOUSE, S.G.R STREAMING)
/// - Servicio (ej. NETFLIX PA, PRIME VIDEO PA, DISNEY+)
/// - Cuenta (Correo de acceso)
/// - Clave (Contraseña)
/// - Perfil (Número o nombre del perfil asignado)
/// - PIN (PIN de 4 dígitos para bloquear el perfil)
/// - Cliente (Nombre de la persona que compra)
/// - Teléfono (Para envío directo por WhatsApp)
/// - Fecha de Compra y Vencimiento
/// - Vendedor (ej. JUAN)
/// - Estado (PAGO / PENDIENTE)
/// - Valor de Venta y Valor de Compra (Costo)
/// - Ganancia Neta calculada automáticamente (Venta - Compra)
/// ============================================================================
class StreamingAccountModel {
  final String id;
  final String proveedor;
  final String servicio;
  final String cuenta;
  final String clave;
  final String perfil;
  final String pin;
  final String cliente;
  final String telefono;
  final DateTime fechaCompra;
  final DateTime fechaVencimiento;
  final String vendedor;
  final String estado; // "PAGO" o "PENDIENTE"
  final double valorVenta;
  final double valorCompra;
  final String notas;

  StreamingAccountModel({
    required this.id,
    required this.proveedor,
    required this.servicio,
    required this.cuenta,
    required this.clave,
    required this.perfil,
    required this.pin,
    required this.cliente,
    this.telefono = '',
    required this.fechaCompra,
    required this.fechaVencimiento,
    this.vendedor = 'JUAN',
    this.estado = 'PAGO',
    required this.valorVenta,
    required this.valorCompra,
    this.notas = '',
  });

  /// Calcula la ganancia neta en pesos/dólares de esta pantalla
  double get ganancia => valorVenta - valorCompra;

  /// Calcula el margen porcentual de ganancia sobre el valor de venta
  double get margenPorcentaje => valorVenta > 0 ? ((ganancia / valorVenta) * 100) : 0.0;

  /// Indica si el estado actual es pagado
  bool get estaPagado => estado.toUpperCase() == 'PAGO';

  /// Días que le quedan a la cuenta antes de vencer
  int get diasRestantes => fechaVencimiento.difference(DateTime.now()).inDays;

  /// Semáforo Verde: Cuenta activa con más de 3 días de vigencia
  bool get esActiva => diasRestantes > 3;

  /// Semáforo Amarillo: Cuenta próxima a vencer (3 días o menos)
  bool get proximoAVencer => diasRestantes >= 0 && diasRestantes <= 3;
  bool get esPorVencer => proximoAVencer;

  /// Semáforo Rojo: Cuenta vencida / inactiva
  bool get estaVencida => DateTime.now().isAfter(fechaVencimiento);
  bool get esVencida => estaVencida;

  /// Texto descriptivo del semáforo
  String get estadoSemaforoTexto {
    if (estaVencida) return 'VENCIDA';
    if (proximoAVencer) return 'POR VENCER';
    return 'ACTIVA';
  }

  /// Crea una copia renovada por 30 días a partir de hoy o de su fecha de vencimiento
  StreamingAccountModel renovar30Dias() {
    final DateTime baseFecha = estaVencida ? DateTime.now() : fechaVencimiento;
    return copyWith(
      fechaCompra: DateTime.now(),
      fechaVencimiento: baseFecha.add(const Duration(days: 30)),
      estado: 'PAGO',
    );
  }

  /// Convierte el modelo a un Map JSON para guardarlo en la base de datos local
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proveedor': proveedor,
      'servicio': servicio,
      'cuenta': cuenta,
      'clave': clave,
      'perfil': perfil,
      'pin': pin,
      'cliente': cliente,
      'telefono': telefono,
      'fechaCompra': fechaCompra.toIso8601String(),
      'fechaVencimiento': fechaVencimiento.toIso8601String(),
      'vendedor': vendedor,
      'estado': estado,
      'valorVenta': valorVenta,
      'valorCompra': valorCompra,
      'notas': notas,
    };
  }

  /// Reconstruye el modelo desde un Map JSON
  factory StreamingAccountModel.fromMap(Map<String, dynamic> map) {
    return StreamingAccountModel(
      id: map['id'] ?? '',
      proveedor: map['proveedor'] ?? '',
      servicio: map['servicio'] ?? 'NETFLIX PA',
      cuenta: map['cuenta'] ?? '',
      clave: map['clave'] ?? '',
      perfil: map['perfil']?.toString() ?? '1',
      pin: map['pin']?.toString() ?? '',
      cliente: map['cliente'] ?? '',
      telefono: map['telefono'] ?? '',
      fechaCompra: map['fechaCompra'] != null
          ? DateTime.parse(map['fechaCompra'])
          : DateTime.now(),
      fechaVencimiento: map['fechaVencimiento'] != null
          ? DateTime.parse(map['fechaVencimiento'])
          : DateTime.now().add(const Duration(days: 30)),
      vendedor: map['vendedor'] ?? 'JUAN',
      estado: map['estado'] ?? 'PAGO',
      valorVenta: (map['valorVenta'] as num?)?.toDouble() ?? 0.0,
      valorCompra: (map['valorCompra'] as num?)?.toDouble() ?? 0.0,
      notas: map['notas'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory StreamingAccountModel.fromJson(String source) =>
      StreamingAccountModel.fromMap(json.decode(source));

  /// Copia el modelo con campos modificados
  StreamingAccountModel copyWith({
    String? id,
    String? proveedor,
    String? servicio,
    String? cuenta,
    String? clave,
    String? perfil,
    String? pin,
    String? cliente,
    String? telefono,
    DateTime? fechaCompra,
    DateTime? fechaVencimiento,
    String? vendedor,
    String? estado,
    double? valorVenta,
    double? valorCompra,
    String? notas,
  }) {
    return StreamingAccountModel(
      id: id ?? this.id,
      proveedor: proveedor ?? this.proveedor,
      servicio: servicio ?? this.servicio,
      cuenta: cuenta ?? this.cuenta,
      clave: clave ?? this.clave,
      perfil: perfil ?? this.perfil,
      pin: pin ?? this.pin,
      cliente: cliente ?? this.cliente,
      telefono: telefono ?? this.telefono,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      vendedor: vendedor ?? this.vendedor,
      estado: estado ?? this.estado,
      valorVenta: valorVenta ?? this.valorVenta,
      valorCompra: valorCompra ?? this.valorCompra,
      notas: notas ?? this.notas,
    );
  }
}
