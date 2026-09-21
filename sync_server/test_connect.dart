import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final connStr = 'mongodb+srv://juangarces028_db_user:Juan.123@cluster0.b4inhbz.mongodb.net/jg_company?retryWrites=true&w=majority';
  print('Connecting to MongoDB Atlas: $connStr');

  try {
    final db = await Db.create(connStr);
    await db.open();
    print('✅ CONEXIÓN EXITOSA A MONGODB ATLAS!');

    print('Listing collections...');
    final collections = await db.getCollectionNames();
    print('Current collections: $collections');

    // Ensure collections exist
    final requiredCols = ['pantallas', 'clientes', 'registros_moto', 'configuracion'];
    for (var col in requiredCols) {
      if (!collections.contains(col)) {
        await db.createCollection(col);
        print('Created collection: $col');
      } else {
        print('Collection exists: $col');
      }
    }

    final updatedCols = await db.getCollectionNames();
    print('✅ Ready! Updated collections: $updatedCols');

    await db.close();
    print('Connection closed successfully.');
  } catch (e, stack) {
    print('❌ Error connecting to MongoDB: $e');
    print(stack);
  }
}
