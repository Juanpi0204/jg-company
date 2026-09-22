import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jg_company_app/models/credit_card_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CreditCardsService Tests', () {
    test('Guarda y sugiere descripciones de compras', () async {
      final sugerenciasIniciales = await CreditCardsService.getDescripcionesSugeridas();
      expect(sugerenciasIniciales.contains('Netflix'), isTrue);

      final tarjeta = await CreditCardsService.add('Visa JG', Colors.blue);
      await CreditCardsService.addMovimiento(tarjeta.id, 'Compra Pantalla Disney', 25000);

      final sugerenciasActualizadas = await CreditCardsService.getDescripcionesSugeridas();
      expect(sugerenciasActualizadas.contains('Compra Pantalla Disney'), isTrue);
      // La más reciente debe estar al principio
      expect(sugerenciasActualizadas.first, equals('Compra Pantalla Disney'));
    });

    test('Calcula ciclo de tarjeta con día de corte correctamente', () async {
      final tarjeta = CreditCardModel(
        id: '1',
        nombre: 'Mastercard',
        color: Colors.red,
        diaCorte: 15,
        diaLimitePago: 5,
        metaMensual: 100000,
        movimientos: [
          CreditCardMovement(
            id: 'm1',
            descripcion: 'Test 1',
            monto: 50000,
            fecha: DateTime.now(),
          ),
        ],
      );

      expect(tarjeta.totalCicloActual, equals(50000));
      expect(tarjeta.porcentajeMeta, equals(0.5));
      expect(tarjeta.metaCumplida, isFalse);
    });

    test('toggleBolsillo conmuta estado e incrementa el notifier en tiempo real', () async {
      int notifications = 0;
      void listener() => notifications++;
      CreditCardsService.notifier.addListener(listener);

      final tarjeta = await CreditCardsService.add('Daviplata', Colors.purple);
      await CreditCardsService.addMovimiento(tarjeta.id, 'Compra Play', 75000);

      final tInicial = (await CreditCardsService.getAll()).first;
      final movId = tInicial.movimientos.first.id;
      expect(tInicial.movimientos.first.subioBolsillo, isFalse);
      expect(tInicial.totalPendienteBolsillo, equals(75000));
      expect(tInicial.totalSubidoBolsillo, equals(0));

      // Activar subido a bolsillo
      await CreditCardsService.toggleBolsillo(tarjeta.id, movId);
      final tSubida = (await CreditCardsService.getAll()).first;
      expect(tSubida.movimientos.first.subioBolsillo, isTrue);
      expect(tSubida.movimientos.first.fechaSubidaBolsillo, isNotNull);
      expect(tSubida.totalPendienteBolsillo, equals(0));
      expect(tSubida.totalSubidoBolsillo, equals(75000));

      // Desactivar de nuevo
      await CreditCardsService.toggleBolsillo(tarjeta.id, movId);
      final tDeshecha = (await CreditCardsService.getAll()).first;
      expect(tDeshecha.movimientos.first.subioBolsillo, isFalse);
      expect(tDeshecha.totalPendienteBolsillo, equals(75000));
      expect(tDeshecha.totalSubidoBolsillo, equals(0));

      expect(notifications, greaterThanOrEqualTo(3));
      CreditCardsService.notifier.removeListener(listener);
    });
  });
}
