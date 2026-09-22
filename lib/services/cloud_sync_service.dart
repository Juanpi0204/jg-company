import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streaming_account_model.dart';
import '../models/client_model.dart';
import '../models/provider_model.dart';
import '../models/storage_service.dart';
import '../models/credit_card_model.dart';
import '../models/debt_model.dart';

/// Estado de la sincronización en la nube
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// ============================================================================
/// [SERVICIO] CloudSyncService — Sincronización automática con MongoDB Atlas
/// ============================================================================
/// Conecta la app con MongoDB Atlas mediante la Data API (HTTPS / REST).
/// Permite:
/// - Auto-sync en tiempo real tras cada cambio (con debounce de 2 segundos)
/// - Auto-sync al pausar o salir de la app (AppLifecycle)
/// - Respaldo manual ("Sincronizar Ahora")
/// - Restauración / descarga de datos desde MongoDB
/// - Prueba de conexión con credenciales
/// ============================================================================
class CloudSyncService {
  // Claves en SharedPreferences
  static const _kConnectionString = 'mongo_connection_string';
  static const _kEndpoint   = 'mongo_data_api_endpoint';
  static const _kApiKey     = 'mongo_data_api_key';
  static const _kCluster    = 'mongo_data_api_cluster';
  static const _kDatabase   = 'mongo_data_api_database';
  static const _kAutoSync   = 'mongo_data_api_autosync';
  static const _kLastSync   = 'mongo_data_api_last_sync';

  // Notificador de estado para la UI
  static final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier<SyncStatus>(SyncStatus.idle);
  static final ValueNotifier<String> statusMessageNotifier = ValueNotifier<String>('Listo');
  static final ValueNotifier<DateTime?> lastSyncNotifier = ValueNotifier<DateTime?>(null);

  // Timer para debounce de auto-guardado
  static Timer? _debounceTimer;

  // ── Configuración ─────────────────────────────────────────────────────────

  static const String defaultConnectionString =
      'mongodb+srv://juangarces028_db_user:Juan.123@cluster0.b4inhbz.mongodb.net/jg_company?retryWrites=true&w=majority';

  static Future<String> getConnectionString() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_kConnectionString);
    if (saved != null && saved.trim().isNotEmpty) return saved;
    return defaultConnectionString;
  }

  static Future<void> saveConnectionString(String connStr) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kConnectionString, connStr.trim());
  }

  static Future<Map<String, String>> getConfig() async {
    final p = await SharedPreferences.getInstance();
    return {
      'connectionString': p.getString(_kConnectionString) ?? defaultConnectionString,
      'endpoint': p.getString(_kEndpoint) ?? '',
      'apiKey': p.getString(_kApiKey) ?? '',
      'cluster': p.getString(_kCluster) ?? 'Cluster0',
      'database': p.getString(_kDatabase) ?? 'jg_company',
    };
  }

  static Future<bool> isAutoSyncEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kAutoSync) ?? true;
  }

  static Future<void> setAutoSyncEnabled(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAutoSync, enabled);
  }

  static Future<DateTime?> getLastSync() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kLastSync);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<bool> isConfigured() async {
    return true;
  }

  static Future<void> saveConfig({
    String? connectionString,
    required String endpoint,
    required String apiKey,
    required String cluster,
    required String database,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (connectionString != null) {
      await p.setString(_kConnectionString, connectionString.trim());
    }
    // Limpiar barras finales del endpoint
    var ep = endpoint.trim();
    if (ep.endsWith('/')) {
      ep = ep.substring(0, ep.length - 1);
    }
    await p.setString(_kEndpoint, ep);
    await p.setString(_kApiKey, apiKey.trim());
    await p.setString(_kCluster, cluster.trim().isEmpty ? 'Cluster0' : cluster.trim());
    await p.setString(_kDatabase, database.trim().isEmpty ? 'jg_company' : database.trim());
  }

  static const _kBridgeUrlKey = 'mongo_bridge_url';
  static const String cloudBridgeUrl = 'https://jg-company.onrender.com';
  static const String localBridgeUrl = 'http://localhost:8089';

  static Future<String> getBridgeUrl() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_kBridgeUrlKey);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host != 'localhost' && host != '127.0.0.1') {
        return cloudBridgeUrl;
      }
    }
    return localBridgeUrl;
  }

  static Future<void> setBridgeUrl(String url) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBridgeUrlKey, url.trim());
  }

  // ── Probar Conexión con Atlas ─────────────────────────────────────────────

  static Future<bool> testConnection({
    String? testConnectionString,
    String? testEndpoint,
    String? testApiKey,
    String? testCluster,
    String? testDatabase,
  }) async {
    // 1. Probar primero el Bridge de MongoDB (Cloud o Local)
    try {
      final bUrl = await getBridgeUrl();
      final resp = await http.get(Uri.parse('$bUrl/status')).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // Fallback: Probar local si estamos en web local
    try {
      final resp = await http.get(Uri.parse('$localBridgeUrl/status')).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // 2. Probar mediante Atlas Data API como fallback
    try {
      final cfg = await getConfig();
      final endpoint = (testEndpoint ?? cfg['endpoint']!).trim();
      final apiKey   = (testApiKey ?? cfg['apiKey']!).trim();
      final cluster  = (testCluster ?? cfg['cluster']!).trim();
      final database = (testDatabase ?? cfg['database']!).trim();

      if (endpoint.isEmpty || apiKey.isEmpty) return false;

      var cleanEp = endpoint;
      if (cleanEp.endsWith('/')) cleanEp = cleanEp.substring(0, cleanEp.length - 1);

      final url = Uri.parse('$cleanEp/action/findOne');
      final headers = {
        'Content-Type': 'application/json',
        'api-key': apiKey,
      };

      final body = jsonEncode({
        'dataSource': cluster,
        'database': database,
        'collection': 'pantallas',
        'filter': {},
      });

      final resp = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Auto-Sync Reactivo con Debounce ───────────────────────────────────────

  static void triggerAutoSync({
    required List<StreamingAccountModel> accounts,
    List<ClientModel>? clients,
    List<ProviderModel>? providers,
    List<CreditCardModel>? creditCards,
    List<DebtModel>? debts,
  }) {
    // Protección: nunca sincronizar si no hay absolutamente ningún dato
    // Esto evita que un dispositivo nuevo (sin datos locales) borre MongoDB
    final hayDatos = accounts.isNotEmpty ||
        (clients?.isNotEmpty ?? false) ||
        (providers?.isNotEmpty ?? false) ||
        (creditCards?.isNotEmpty ?? false) ||
        (debts?.isNotEmpty ?? false);
    if (!hayDatos) {
      print('⚠️ [AUTO-SYNC] Ignorado: no hay datos locales. MongoDB protegido.');
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 2000), () async {
      final auto = await isAutoSyncEnabled();
      final configured = await isConfigured();
      if (auto && configured) {
        await syncToCloud(
          accounts: accounts,
          clients: clients,
          providers: providers,
          creditCards: creditCards,
          debts: debts,
        );
      }
    });
  }

  // ── Sincronizar hacia MongoDB Atlas (Subir Todo) ──────────────────────────

  static Future<bool> syncToCloud({
    required List<StreamingAccountModel> accounts,
    List<ClientModel>? clients,
    List<ProviderModel>? providers,
    List<CreditCardModel>? creditCards,
    List<DebtModel>? debts,
    bool forceEmpty = false,
  }) async {
    statusNotifier.value = SyncStatus.syncing;
    statusMessageNotifier.value = 'Sincronizando con MongoDB Atlas...';

    try {
      final listaClientes = clients ?? await ClientsService.getAll();
      final listaProveedores = providers ?? await ProvidersService.getAll();
      final listaTarjetas = creditCards ?? await CreditCardsService.getAll();
      final listaDeudas = debts ?? await DebtsService.getAll();

      // Protección: si todo está vacío y no es forceEmpty, no sincronizar
      final hayDatos = accounts.isNotEmpty || listaClientes.isNotEmpty ||
          listaProveedores.isNotEmpty || listaTarjetas.isNotEmpty || listaDeudas.isNotEmpty;
      if (!hayDatos && !forceEmpty) {
        print('⚠️ [SYNC] Todos los datos están vacíos. Sync cancelado para proteger MongoDB.');
        statusNotifier.value = SyncStatus.idle;
        statusMessageNotifier.value = 'Sin datos para sincronizar';
        return false;
      }
      // 1. Intentar primero con el Mongo Sync Bridge (Cloud o Local)
      try {
        final bUrl = await getBridgeUrl();
        final payload = jsonEncode({
          'accounts': accounts.map((a) => a.toMap()).toList(),
          'clients': listaClientes.map((c) => c.toMap()).toList(),
          'providers': listaProveedores.map((p) => p.toMap()).toList(),
          'creditCards': listaTarjetas.map((c) => c.toMap()).toList(),
          'debts': listaDeudas.map((d) => d.toMap()).toList(),
          'forceEmpty': forceEmpty,
        });

        var bridgeResp = await http.post(
          Uri.parse('$bUrl/sync'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        ).timeout(const Duration(seconds: 8));

        // Fallback a localBridgeUrl si el cloud falló y estamos en PC
        if (bridgeResp.statusCode != 200 && bUrl != localBridgeUrl) {
          try {
            bridgeResp = await http.post(
              Uri.parse('$localBridgeUrl/sync'),
              headers: {'Content-Type': 'application/json'},
              body: payload,
            ).timeout(const Duration(seconds: 4));
          } catch (_) {}
        }

        print('🌐 [SYNC] Respuesta del Bridge: ${bridgeResp.statusCode} - ${bridgeResp.body}');

        if (bridgeResp.statusCode == 200) {
          final now = DateTime.now();
          final p = await SharedPreferences.getInstance();
          await p.setString(_kLastSync, now.toIso8601String());

          lastSyncNotifier.value = now;
          statusNotifier.value = SyncStatus.success;
          statusMessageNotifier.value = 'Respaldo exitoso en MongoDB Atlas';
          return true;
        }
      } catch (e) {
        print('⚠️ [SYNC] Error conectando al bridge: $e');
      }

      // 2. Fallback: Data API si está configurada
      final cfg = await getConfig();
      final endpoint = cfg['endpoint']!;
      final apiKey   = cfg['apiKey']!;
      final cluster  = cfg['cluster']!;
      final database = cfg['database']!;

      if (endpoint.isEmpty || apiKey.isEmpty) {
        throw Exception('No se pudo conectar con el servicio de MongoDB');
      }

      final headers = {
        'Content-Type': 'application/json',
        'api-key': apiKey,
      };

      // Limpiar y reinsertar pantallas
      await http.post(
        Uri.parse('$endpoint/action/deleteMany'),
        headers: headers,
        body: jsonEncode({
          'dataSource': cluster,
          'database': database,
          'collection': 'pantallas',
          'filter': {},
        }),
      );

      if (accounts.isNotEmpty) {
        final docsPantallas = accounts.map((a) => {
          ...a.toMap(),
          '_id': a.id,
          'updatedAt': DateTime.now().toIso8601String(),
        }).toList();

        await http.post(
          Uri.parse('$endpoint/action/insertMany'),
          headers: headers,
          body: jsonEncode({
            'dataSource': cluster,
            'database': database,
            'collection': 'pantallas',
            'documents': docsPantallas,
          }),
        );
      }

      // Subir Clientes
      await http.post(
        Uri.parse('$endpoint/action/deleteMany'),
        headers: headers,
        body: jsonEncode({
          'dataSource': cluster,
          'database': database,
          'collection': 'clientes',
          'filter': {},
        }),
      );

      if (listaClientes.isNotEmpty) {
        final docsClientes = listaClientes.map((c) => {
          ...c.toMap(),
          '_id': c.id,
          'updatedAt': DateTime.now().toIso8601String(),
        }).toList();

        await http.post(
          Uri.parse('$endpoint/action/insertMany'),
          headers: headers,
          body: jsonEncode({
            'dataSource': cluster,
            'database': database,
            'collection': 'clientes',
            'documents': docsClientes,
          }),
        );
      }

      final now = DateTime.now();
      final p = await SharedPreferences.getInstance();
      await p.setString(_kLastSync, now.toIso8601String());

      lastSyncNotifier.value = now;
      statusNotifier.value = SyncStatus.success;
      statusMessageNotifier.value = 'Respaldo exitoso en la nube';
      return true;
    } catch (e) {
      statusNotifier.value = SyncStatus.error;
      statusMessageNotifier.value = 'Error al sincronizar: $e';
      return false;
    }
  }

  // ── Descargar de MongoDB Atlas (Restaurar) ─────────────────────────────────

  static Future<Map<String, dynamic>?> downloadFromCloud() async {
    statusNotifier.value = SyncStatus.syncing;
    statusMessageNotifier.value = 'Descargando desde MongoDB Atlas...';

    try {
      // 1. Intentar con Bridge (Cloud o Local)
      try {
        final bUrl = await getBridgeUrl();
        var bridgeResp = await http.get(Uri.parse('$bUrl/pull')).timeout(const Duration(seconds: 8));
        if (bridgeResp.statusCode != 200 && bUrl != localBridgeUrl) {
          try {
            bridgeResp = await http.get(Uri.parse('$localBridgeUrl/pull')).timeout(const Duration(seconds: 4));
          } catch (_) {}
        }
        if (bridgeResp.statusCode == 200) {
          final data = jsonDecode(bridgeResp.body) as Map<String, dynamic>;
          final List docsP = data['accounts'] ?? [];
          final List docsC = data['clients'] ?? [];
          final List docsPR = data['providers'] ?? [];

          final cuentas = docsP.map((d) {
            final map = Map<String, dynamic>.from(d);
            if (map['id'] == null && map['_id'] != null) map['id'] = map['_id'];
            return StreamingAccountModel.fromMap(map);
          }).toList();

          final clientes = docsC.map((d) {
            final map = Map<String, dynamic>.from(d);
            if (map['id'] == null && map['_id'] != null) map['id'] = map['_id'];
            return ClientModel.fromMap(map);
          }).toList();

          if (docsPR.isNotEmpty) {
            final proveedores = docsPR.map((d) {
              final map = Map<String, dynamic>.from(d);
              if (map['id'] == null && map['_id'] != null) map['id'] = map['_id'];
              return ProviderModel.fromMap(map);
            }).toList();
            await ProvidersService.save(proveedores);
          }

          // Restaurar tarjetas de crédito si existen
          final List docsTC = data['creditCards'] ?? [];
          if (docsTC.isNotEmpty) {
            final tarjetas = docsTC.map((d) {
              final map = Map<String, dynamic>.from(d);
              if (map['id'] == null && map['_id'] != null) map['id'] = map['_id'];
              return CreditCardModel.fromMap(map);
            }).toList();
            await CreditCardsService.save(tarjetas);
          }

          // Restaurar deudas si existen
          final List docsDebts = data['debts'] ?? [];
          if (docsDebts.isNotEmpty) {
            final deudas = docsDebts.map((d) {
              final map = Map<String, dynamic>.from(d);
              if (map['id'] == null && map['_id'] != null) map['id'] = map['_id'];
              return DebtModel.fromMap(map);
            }).toList();
            await DebtsService.save(deudas);
          }
          await ClientsService.save(clientes);
          await StorageService.saveAccounts(cuentas);

          final now = DateTime.now();
          final p = await SharedPreferences.getInstance();
          await p.setString(_kLastSync, now.toIso8601String());

          lastSyncNotifier.value = now;
          statusNotifier.value = SyncStatus.success;
          statusMessageNotifier.value = 'Datos restaurados desde la nube';

          return {
            'cuentas': cuentas,
            'clientes': clientes,
          };
        }
      } catch (_) {}

      // 2. Fallback Data API
      final cfg = await getConfig();
      final endpoint = cfg['endpoint']!;
      final apiKey   = cfg['apiKey']!;
      final cluster  = cfg['cluster']!;
      final database = cfg['database']!;

      if (endpoint.isEmpty || apiKey.isEmpty) return null;

      final headers = {
        'Content-Type': 'application/json',
        'api-key': apiKey,
      };

      final respPantallas = await http.post(
        Uri.parse('$endpoint/action/find'),
        headers: headers,
        body: jsonEncode({
          'dataSource': cluster,
          'database': database,
          'collection': 'pantallas',
          'filter': {},
          'sort': {'fechaVencimiento': 1},
        }),
      );

      final respClientes = await http.post(
        Uri.parse('$endpoint/action/find'),
        headers: headers,
        body: jsonEncode({
          'dataSource': cluster,
          'database': database,
          'collection': 'clientes',
          'filter': {},
          'sort': {'nombre': 1},
        }),
      );

      if (respPantallas.statusCode != 200 || respClientes.statusCode != 200) {
        throw Exception('Respuesta no válida de Atlas');
      }

      final dataPantallas = jsonDecode(respPantallas.body);
      final dataClientes  = jsonDecode(respClientes.body);

      final List docsP = dataPantallas['documents'] ?? [];
      final List docsC = dataClientes['documents'] ?? [];

      final cuentas = docsP.map((d) {
        final map = Map<String, dynamic>.from(d);
        if (map['id'] == null && map['_id'] != null) map['id'] = map['_id'];
        return StreamingAccountModel.fromMap(map);
      }).toList();

      final clientes = docsC.map((d) {
        final map = Map<String, dynamic>.from(d);
        if (map['id'] == null && map['_id'] != null) map['id'] = map['_id'];
        return ClientModel.fromMap(map);
      }).toList();

      await ClientsService.save(clientes);
      await StorageService.saveAccounts(cuentas);

      final now = DateTime.now();
      final p = await SharedPreferences.getInstance();
      await p.setString(_kLastSync, now.toIso8601String());

      lastSyncNotifier.value = now;
      statusNotifier.value = SyncStatus.success;
      statusMessageNotifier.value = 'Datos restaurados desde la nube';

      return {
        'cuentas': cuentas,
        'clientes': clientes,
      };
    } catch (e) {
      statusNotifier.value = SyncStatus.error;
      statusMessageNotifier.value = 'Error al descargar: $e';
      return null;
    }
  }
}
