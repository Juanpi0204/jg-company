import 'package:flutter_test/flutter_test.dart';
import 'package:jg_company_app/models/smart_parser_service.dart';

void main() {
  group('SmartParserService Tests', () {
    test('Parsea reemplazo de cuenta dañada ignorando el primer correo', () {
      const msg = '''
hm15d8b@extraped.com
Reemplazo por

 C.S N3TFLIX🎈  
CORREO: trelasmin6@outlook.sa 
CLAVE: IE2005 
perfil 4 pin: 2411 
fecha de compra: 1-septiembre
''';

      final result = SmartParserService.parse(msg);

      expect(result.correo, equals('trelasmin6@outlook.sa'));
      expect(result.clave, equals('IE2005'));
      expect(result.perfil, equals('4'));
      expect(result.pin, equals('2411'));
      expect(result.servicio, equals('NETFLIX PA'));
    });

    test('Parsea actualización de clave ignorando palabra clave en saludo', () {
      const msg = '''
Bu3n dí4 ✨❤️
Tuvimos actualización de clave🍿, te adjunto los datos en dado caso que los requieras🫡

 C.S N3TFLIX🎈  
CORREO: camata323+d65g8r4@zohomail.com 
CLAVE: caronetsemi@12 
perfil 3 pin: 2030 
fecha de compra: 20-septiembre  pago 320 5470008 House
''';

      final result = SmartParserService.parse(msg);

      expect(result.correo, equals('camata323+d65g8r4@zohomail.com'));
      expect(result.clave, equals('caronetsemi@12'));
      expect(result.perfil, equals('3'));
      expect(result.pin, equals('2030'));
      expect(result.servicio, equals('NETFLIX PA'));
    });

    test('Parsea formato directo correo:clave', () {
      const msg = 'usuario@gmail.com:claveSegura123';
      final result = SmartParserService.parse(msg);
      expect(result.correo, equals('usuario@gmail.com'));
      expect(result.clave, equals('claveSegura123'));
    });

    test('Parsea garantia con cuenta danada y nueva', () {
      const msg = '''
cuenta_rota@gmail.com
garantia
CORREO: nueva@gmail.com
CLAVE: nueva123
perfil 1 pin: 9999
''';
      final result = SmartParserService.parse(msg);
      expect(result.correo, equals('nueva@gmail.com'));
      expect(result.clave, equals('nueva123'));
      expect(result.perfil, equals('1'));
      expect(result.pin, equals('9999'));
    });

    test('Si hay un correo suelto y otro con CORREO: toma el de CORREO:', () {
      const msg = '''
viejo@mail.com
actualizacion
CORREO: oficial@mail.com
CLAVE: pass2026
''';
      final result = SmartParserService.parse(msg);
      expect(result.correo, equals('oficial@mail.com'));
      expect(result.clave, equals('pass2026'));
    });

    test('Caso exacto del usuario con + en el correo y una sola linea', () {
      const msg = '''Bu3n dí4 ✨❤️
Tuvimos actualización de clave🍿, te adjunto los datos en dado caso que los requieras🫡

 C.S N3TFLIX🎈  CORREO: camata323+hfj647@zohomail.com CLAVE: Sz3y@1734 perfil 3 pin: 2030''';
      final result = SmartParserService.parse(msg);
      expect(result.correo, equals('camata323+hfj647@zohomail.com'));
      expect(result.clave, equals('Sz3y@1734'));
      expect(result.perfil, equals('3'));
      expect(result.pin, equals('2030'));
      expect(result.servicio, equals('NETFLIX PA'));

      // Test WhatsApp URI behavior: %2B debe codificarse como %252B para que wa.me no lo convierta en espacio
      final waMsg = '📧 *Correo:* ${result.correo}';
      final encoded = Uri.encodeComponent(waMsg).replaceAll('%2B', '%252B');
      final url = Uri.parse('https://wa.me/573001234567?text=$encoded');
      expect(url.toString(), contains('%252B'));

      // Prueba con espacio alrededor del +
      final resSpace = SmartParserService.parse('CORREO: camata323 + hfj647@zohomail.com CLAVE: 1234');
      expect(resSpace.correo, equals('camata323+hfj647@zohomail.com'));

      // Prueba con espacio después del +
      final resSpaceAfter = SmartParserService.parse('CORREO: camata323+ hfj647@zohomail.com CLAVE: 1234');
      expect(resSpaceAfter.correo, equals('camata323+hfj647@zohomail.com'));

      // Prueba con espacio antes del +
      final resSpaceBefore = SmartParserService.parse('CORREO: camata323 +hfj647@zohomail.com CLAVE: 1234');
      expect(resSpaceBefore.correo, equals('camata323+hfj647@zohomail.com'));

      // Prueba con emoji plus
      final resEmoji = SmartParserService.parse('CORREO: camata323➕hfj647@zohomail.com CLAVE: 1234');
      expect(resEmoji.correo, equals('camata323+hfj647@zohomail.com'));

      // Prueba con fullwidth plus
      final resFullWidth = SmartParserService.parse('CORREO: camata323＋hfj647@zohomail.com CLAVE: 1234');
      expect(resFullWidth.correo, equals('camata323+hfj647@zohomail.com'));

      // Prueba con caracteres invisibles de WhatsApp (LTR mark \u200E)
      final resInvisible = SmartParserService.parse('CORREO: camata323\u200E+\u200Ehfj647@zohomail.com CLAVE: 1234');
      expect(resInvisible.correo, equals('camata323+hfj647@zohomail.com'));

      // Prueba con URL encoded plus %2B
      final resUrlEncoded = SmartParserService.parse('CORREO: camata323%2Bhfj647@zohomail.com CLAVE: 1234');
      expect(resUrlEncoded.correo, equals('camata323+hfj647@zohomail.com'));
    });
  });
}
