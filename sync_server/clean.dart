import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final db = await Db.create(
    'mongodb+srv://juangarces028_db_user:Juan.123@cluster0.b4inhbz.mongodb.net/jg_company?retryWrites=true&w=majority',
  );
  await db.open();
  await db.collection('pantallas').deleteMany({'id': 'test-1'});
  await db.collection('clientes').deleteMany({'id': 'cli-1'});
  print('✅ Test records cleaned.');
  await db.close();
}
