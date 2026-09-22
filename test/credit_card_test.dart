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
  });
}
