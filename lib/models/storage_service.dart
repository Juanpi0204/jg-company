import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'streaming_account_model.dart';
import 'mock_data.dart';

/// ============================================================================
/// [MODELO / SERVICIO] StorageService
/// ============================================================================
/// Gestiona la base de datos local en el dispositivo usando SharedPreferences.
/// Permite:
/// - Cargar cuentas guardadas (o precargar los datos de Excel si es la primera vez).
/// - Guardar la lista completa de cuentas actualizada.
/// - Exportar respaldo en formato JSON y restaurar desde respaldo.
/// ============================================================================
class StorageService {
  static const String _accountsKey = 'jg_company_streaming_accounts_v1';

  /// Carga todas las cuentas guardadas. Si no hay datos, inicializa con MockData.
  static Future<List<StreamingAccountModel>> loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_accountsKey);

      if (jsonString == null || jsonString.isEmpty) {
        // Primera ejecución: precargar datos del Excel y guardar
        final initial = MockData.initialAccounts;
        await saveAccounts(initial);
        return initial;
      }

      final List<dynamic> decodedList = json.decode(jsonString);
      return decodedList
          .map((item) => StreamingAccountModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al cargar cuentas de almacenamiento local: $e');
      return MockData.initialAccounts;
    }
  }

  /// Guarda la lista completa de cuentas en el almacenamiento local
  static Future<bool> saveAccounts(List<StreamingAccountModel> accounts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = accounts.map((acc) => acc.toMap()).toList();
      final jsonString = json.encode(listMap);
      return await prefs.setString(_accountsKey, jsonString);
    } catch (e) {
      print('Error al guardar cuentas: $e');
      return false;
    }
  }

  /// Exporta los datos a un texto JSON para copia de seguridad
  static Future<String> exportBackup(List<StreamingAccountModel> accounts) async {
    final listMap = accounts.map((acc) => acc.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(listMap);
  }

  /// Restaura los datos a partir de una cadena JSON
  static Future<List<StreamingAccountModel>?> importBackup(String jsonContent) async {
    try {
      final List<dynamic> decoded = json.decode(jsonContent);
      final list = decoded
          .map((item) => StreamingAccountModel.fromMap(item as Map<String, dynamic>))
          .toList();
      await saveAccounts(list);
      return list;
    } catch (e) {
      print('Error al importar backup: $e');
      return null;
    }
  }
}
