import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final db = await Db.create(
    'mongodb+srv://juangarces028_db_user:Juan.123@cluster0.b4inhbz.mongodb.net/jg_company?retryWrites=true&w=majority',
  );
  await db.open();
  final pCount = await db.collection('pantallas').count();
  final cCount = await db.collection('clientes').count();
  print('Atlas Pantallas count: $pCount');
  print('Atlas Clientes count: $cCount');
  final clients = await db.collection('clientes').find().toList();
  print('Atlas Clientes: $clients');
  final accounts = await db.collection('pantallas').find().toList();
  print('Atlas Pantallas: $accounts');
  await db.close();
}
