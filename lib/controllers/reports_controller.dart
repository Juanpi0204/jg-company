import 'package:flutter/material.dart';
import '../models/streaming_account_model.dart';

/// ============================================================================
/// [CONTROLADOR] ReportsController
/// ============================================================================
/// Procesa y calcula los indicadores financieros del negocio de pantallas:
/// - Ingresos Totales (Ventas brutas)
/// - Costos Totales de adquisición de cuentas/pantallas
/// - Ganancia Neta Total ($) y Margen de Utilidad (%)
/// - Desglose financiero por Servicio (Netflix, Prime, Disney, etc.)
/// - Desglose financiero por Proveedor (Digital House, S.G.R, etc.)
/// - Cuentas por cobrar (Dinero retenido en estado PENDIENTE)
/// ============================================================================
class ReportsController extends ChangeNotifier {
  /// Calcula el total recaudado/vendido
  static double totalVentas(List<StreamingAccountModel> accounts) {
    return accounts.fold(0.0, (sum, acc) => sum + acc.valorVenta);
  }

  /// Calcula el costo total invertido en proveedores
  static double totalCostos(List<StreamingAccountModel> accounts) {
    return accounts.fold(0.0, (sum, acc) => sum + acc.valorCompra);
  }

  /// Calcula la ganancia neta total (Ventas - Costos)
  static double gananciaNeta(List<StreamingAccountModel> accounts) {
    return totalVentas(accounts) - totalCostos(accounts);
  }

  /// Calcula el margen porcentual general de ganancia
  static double margenPorcentaje(List<StreamingAccountModel> accounts) {
    final ventas = totalVentas(accounts);
    if (ventas <= 0) return 0.0;
    return (gananciaNeta(accounts) / ventas) * 100;
  }

  /// Calcula el total de dinero cobrado (Estado PAGO)
  static double dineroRecaudado(List<StreamingAccountModel> accounts) {
    return accounts
        .where((acc) => acc.estaPagado)
        .fold(0.0, (sum, acc) => sum + acc.valorVenta);
  }

  /// Calcula el dinero pendiente de cobro (Estado PENDIENTE)
  static double dineroPorCobrar(List<StreamingAccountModel> accounts) {
    return accounts
        .where((acc) => !acc.estaPagado)
        .fold(0.0, (sum, acc) => sum + acc.valorVenta);
  }

  /// Cantidad de clientes al día (PAGO)
  static int clientesPagados(List<StreamingAccountModel> accounts) {
    return accounts.where((acc) => acc.estaPagado).length;
  }

  /// Cantidad de clientes con pagos pendientes
  static int clientesPendientes(List<StreamingAccountModel> accounts) {
    return accounts.where((acc) => !acc.estaPagado).length;
  }

  /// Agrupa las estadísticas financieras por servicio (Netflix, Prime, etc.)
  static Map<String, Map<String, dynamic>> desglosePorServicio(
      List<StreamingAccountModel> accounts) {
    final Map<String, Map<String, dynamic>> breakdown = {};

    for (var acc in accounts) {
      if (!breakdown.containsKey(acc.servicio)) {
        breakdown[acc.servicio] = {
          'cantidad': 0,
          'ventas': 0.0,
          'costos': 0.0,
          'ganancia': 0.0,
        };
      }
      breakdown[acc.servicio]!['cantidad'] =
          (breakdown[acc.servicio]!['cantidad'] as int) + 1;
      breakdown[acc.servicio]!['ventas'] =
          (breakdown[acc.servicio]!['ventas'] as double) + acc.valorVenta;
      breakdown[acc.servicio]!['costos'] =
          (breakdown[acc.servicio]!['costos'] as double) + acc.valorCompra;
      breakdown[acc.servicio]!['ganancia'] =
          (breakdown[acc.servicio]!['ganancia'] as double) + acc.ganancia;
    }

    return breakdown;
  }

  /// Agrupa las estadísticas financieras por proveedor (Digital House, S.G.R, etc.)
  static Map<String, Map<String, dynamic>> desglosePorProveedor(
      List<StreamingAccountModel> accounts) {
    final Map<String, Map<String, dynamic>> breakdown = {};

    for (var acc in accounts) {
      if (!breakdown.containsKey(acc.proveedor)) {
        breakdown[acc.proveedor] = {
          'cantidad': 0,
          'costos': 0.0,
          'ventas': 0.0,
          'ganancia': 0.0,
        };
      }
      breakdown[acc.proveedor]!['cantidad'] =
          (breakdown[acc.proveedor]!['cantidad'] as int) + 1;
      breakdown[acc.proveedor]!['costos'] =
          (breakdown[acc.proveedor]!['costos'] as double) + acc.valorCompra;
      breakdown[acc.proveedor]!['ventas'] =
          (breakdown[acc.proveedor]!['ventas'] as double) + acc.valorVenta;
      breakdown[acc.proveedor]!['ganancia'] =
          (breakdown[acc.proveedor]!['ganancia'] as double) + acc.ganancia;
    }

    return breakdown;
  }
}
