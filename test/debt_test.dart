import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jg_company_app/models/debt_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DebtsService & DebtModel Tests', () {
    test('Crea una deuda correctamente y calcula saldos iniciales', () async {
      final deuda = await DebtsService.add(
        acreedor: 'Bancolombia',
        montoTotal: 500000,
        descripcion: 'Préstamo personal',
        color: Colors.pink,
      );

      expect(deuda.acreedor, equals('Bancolombia'));
      expect(deuda.montoTotal, equals(500000));
      expect(deuda.totalAbonado, equals(0.0));
      expect(deuda.saldoRestante, equals(500000.0));
      expect(deuda.porcentajePagado, equals(0.0));
      expect(deuda.estaPagada, isFalse);
    });

    test('Registrar abonos descuenta el saldo en tiempo real y notifica', () async {
      int notifications = 0;
      void listener() => notifications++;
      DebtsService.notifier.addListener(listener);

      final deuda = await DebtsService.add(
        acreedor: 'Tío Carlos',
        montoTotal: 200000,
      );

      // Primer abono: $50.000
      final abono1 = await DebtsService.addAbono(
        deudaId: deuda.id,
        monto: 50000,
        nota: 'Primer pago por Nequi',
      );
      expect(abono1, isNotNull);

      var lista = await DebtsService.getAll();
      var actualizada = lista.firstWhere((d) => d.id == deuda.id);
      expect(actualizada.totalAbonado, equals(50000.0));
      expect(actualizada.saldoRestante, equals(150000.0));
      expect(actualizada.porcentajePagado, equals(0.25));
      expect(actualizada.estaPagada, isFalse);

      // Segundo abono: $150.000 (saldar deuda)
      await DebtsService.addAbono(
        deudaId: deuda.id,
        monto: 150000,
        nota: 'Pago final en efectivo',
      );

      lista = await DebtsService.getAll();
      actualizada = lista.firstWhere((d) => d.id == deuda.id);
      expect(actualizada.totalAbonado, equals(200000.0));
      expect(actualizada.saldoRestante, equals(0.0));
      expect(actualizada.porcentajePagado, equals(1.0));
      expect(actualizada.estaPagada, isTrue);

      expect(notifications, greaterThanOrEqualTo(3));
      DebtsService.notifier.removeListener(listener);
    });

    test('Eliminar un abono recalcula el saldo restante', () async {
      final deuda = await DebtsService.add(
        acreedor: 'Almacén Éxito',
        montoTotal: 100000,
      );

      final abono = await DebtsService.addAbono(
        deudaId: deuda.id,
        monto: 40000,
        nota: 'Abono 1',
      );

      var lista = await DebtsService.getAll();
      expect(lista.first.saldoRestante, equals(60000.0));

      // Eliminar el abono
      await DebtsService.deleteAbono(deuda.id, abono!.id);

      lista = await DebtsService.getAll();
      expect(lista.first.abonos.isEmpty, isTrue);
      expect(lista.first.totalAbonado, equals(0.0));
      expect(lista.first.saldoRestante, equals(100000.0));
    });
  });
}
