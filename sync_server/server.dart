import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoSyncBridge {
  static const int port = 8089;
  static String connectionString =
      'mongodb+srv://juangarces028_db_user:Juan.123@cluster0.b4inhbz.mongodb.net/jg_company?retryWrites=true&w=majority';

  Db? _db;

  Future<Db> getDb() async {
    if (_db != null && _db!.isConnected) {
      return _db!;
    }
    _db = await Db.create(connectionString);
    await _db!.open();
    return _db!;
  }

  Handler get handler {
    final router = Router();

    // ── Status ──────────────────────────────────────────────────────────────
    router.get('/status', (Request req) async {
      try {
        final db = await getDb();
        final cols = await db.getCollectionNames();
        return Response.ok(
          jsonEncode({
            'status': 'connected',
            'database': 'jg_company',
            'collections': cols,
            'timestamp': DateTime.now().toIso8601String(),
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'status': 'error', 'message': e.toString()}),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    // ── Subir datos (Push / Sync) ───────────────────────────────────────────
    router.post('/sync', (Request req) async {
      try {
        final rawBody = await req.readAsString();
        final payload = jsonDecode(rawBody) as Map<String, dynamic>;
        final db = await getDb();

        final accounts = (payload['accounts'] as List?) ?? [];
        final clients = (payload['clients'] as List?) ?? [];

        print('📥 [SYNC] Recibido: ${accounts.length} pantallas, ${clients.length} clientes');

        // 1. Sincronizar Pantallas
        final colPantallas = db.collection('pantallas');
        final currentAccountIds = accounts
            .map((a) => (a as Map)['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        if (currentAccountIds.isNotEmpty) {
          await colPantallas.deleteMany(where.nin('id', currentAccountIds));
          for (final acc in accounts) {
            final accMap = Map<String, dynamic>.from(acc as Map);
            final id = accMap['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              await colPantallas.replaceOne(
                where.eq('id', id),
                accMap,
                upsert: true,
              );
            }
          }
        } else {
          await colPantallas.deleteMany({});
        }

        // 2. Sincronizar Clientes
        final colClientes = db.collection('clientes');
        final currentClientIds = clients
            .map((c) => (c as Map)['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        if (currentClientIds.isNotEmpty) {
          await colClientes.deleteMany(where.nin('id', currentClientIds));
          for (final cl in clients) {
            final clMap = Map<String, dynamic>.from(cl as Map);
            final id = clMap['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              await colClientes.replaceOne(
                where.eq('id', id),
                clMap,
                upsert: true,
              );
            }
          }
        } else {
          await colClientes.deleteMany({});
        }

        print('✅ [SYNC EXITOSO] MongoDB Atlas actualizado. (${accounts.length} pantallas, ${clients.length} clientes)');

        return Response.ok(
          jsonEncode({
            'ok': true,
            'message': 'Sincronización exitosa con MongoDB Atlas',
            'syncedAccounts': accounts.length,
            'syncedClients': clients.length,
            'timestamp': DateTime.now().toIso8601String(),
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, stack) {
        print('❌ [SYNC ERROR]: $e');
        print(stack);
        return Response.internalServerError(
          body: jsonEncode({'ok': false, 'error': e.toString()}),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    // ── Descargar datos (Pull) ──────────────────────────────────────────────
    router.get('/pull', (Request req) async {
      try {
        final db = await getDb();
        final colPantallas = db.collection('pantallas');
        final colClientes = db.collection('clientes');

        final pantallasList = await colPantallas.find().toList();
        final clientesList = await colClientes.find().toList();

        for (final item in pantallasList) {
          item.remove('_id');
        }
        for (final item in clientesList) {
          item.remove('_id');
        }

        return Response.ok(
          jsonEncode({
            'ok': true,
            'accounts': pantallasList,
            'clients': clientesList,
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'ok': false, 'error': e.toString()}),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    // Middleware de CORS completo que maneja preflight OPTIONS
    Handler corsMiddleware(Handler innerHandler) {
      return (Request req) async {
        if (req.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
            'Access-Control-Max-Age': '86400',
          });
        }
        final resp = await innerHandler(req);
        return resp.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        });
      };
    }

    final pipeline = Pipeline()
        .addMiddleware(corsMiddleware)
        .addHandler(router);

    return pipeline;
  }
}

void main() async {
  final bridge = MongoSyncBridge();
  final server = await shelf_io.serve(bridge.handler, InternetAddress.anyIPv4, MongoSyncBridge.port);
  print('====================================================');
  print('🚀 MONGO SYNC BRIDGE ACTIVO en http://localhost:${server.port}');
  print('Conectado a cluster: cluster0.b4inhbz.mongodb.net/jg_company');
  print('====================================================');
}
