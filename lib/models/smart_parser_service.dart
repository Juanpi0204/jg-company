/// ============================================================================
/// [MODELO / SERVICIO] SmartParserService (Detector Inteligente de Cuentas)
/// ============================================================================
/// Analiza cualquier texto enviado por revendedores o proveedores de streaming
/// (por ejemplo, mensajes de WhatsApp con formatos variados) y extrae de forma
/// automática:
/// - Correo electrónico
/// - Contraseña / Clave
/// - Número de perfil
/// - PIN de 4 dígitos
/// - Tipo de servicio (Netflix, Prime Video, Disney, etc.)
/// - Fecha de vencimiento si viene en el texto
/// ============================================================================
class SmartParsedResult {
  final String? correo;
  final String? clave;
  final String? perfil;
  final String? pin;
  final String? servicio;
  final String? proveedor;
  final DateTime? fechaVencimiento;
  final String textoOriginal;

  SmartParsedResult({
    this.correo,
    this.clave,
    this.perfil,
    this.pin,
    this.servicio,
    this.proveedor,
    this.fechaVencimiento,
    required this.textoOriginal,
  });

  bool get tieneDatos => correo != null || clave != null || pin != null || perfil != null;
}

class SmartParserService {
  /// Analiza un texto arbitrario y extrae los campos de la cuenta
  static SmartParsedResult parse(String text) {
    if (text.trim().isEmpty) {
      return SmartParsedResult(textoOriginal: text);
    }

    String? correo;
    String? clave;
    String? perfil;
    String? pin;
    String? servicio;
    String? proveedor;
    DateTime? fechaVencimiento;

    // 1. Detectar Correo Electrónico
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final emailMatch = emailRegex.firstMatch(text);
    if (emailMatch != null) {
      correo = emailMatch.group(0)?.trim();
    }

    // Dividir en líneas para análisis por contexto
    final lines = text.split(RegExp(r'[\r\n]+'));

    for (var line in lines) {
      final cleanLine = line.trim();
      final lower = cleanLine.toLowerCase();

      // 2. Detectar Servicio
      if (servicio == null) {
        if (lower.contains('netflix')) {
          servicio = 'NETFLIX PA';
        } else if (lower.contains('prime') || lower.contains('amazon')) {
          servicio = 'PRIME VIDEO PA';
        } else if (lower.contains('disney')) {
          servicio = 'DISNEY+ PA';
        } else if (lower.contains('max') || lower.contains('hbo')) {
          servicio = 'MAX PA';
        } else if (lower.contains('spotify')) {
          servicio = 'SPOTIFY FAMILIAR';
        } else if (lower.contains('crunchyroll')) {
          servicio = 'CRUNCHYROLL';
        }
      }

      // 3. Detectar Contraseña / Clave
      // PRIMERA PASADA: solo líneas con separador EXPLÍCITO (clave: valor, clave= valor)
      // Esto evita capturar "actualización de clave🍿" donde clave aparece sin separador
      if (clave == null) {
        final claveConSeparadorRegex = RegExp(
          r'(?:clave|password|pass|contrase[ñn]a|pwd)\s*[:=]\s*([^\s,;]+)',
          caseSensitive: false,
        );
        final claveMatch = claveConSeparadorRegex.firstMatch(cleanLine);
        if (claveMatch != null) {
          final candidata = claveMatch.group(1)?.trim() ?? '';
          // Validar que no sea solo emojis o símbolo raro (longitud mínima razonable)
          if (candidata.isNotEmpty && candidata.length >= 4) {
            clave = candidata;
          }
        }
      }

      // 4. Detectar Perfil
      if (perfil == null) {
        final perfilRegex = RegExp(
          r'(?:perfil|pantalla|screen|profile)\s*[:=\-]?\s*([0-9a-zA-Z]+)',
          caseSensitive: false,
        );
        final perfilMatch = perfilRegex.firstMatch(cleanLine);
        if (perfilMatch != null) {
          perfil = perfilMatch.group(1)?.trim();
        }
      }

      // 5. Detectar PIN
      if (pin == null) {
        final pinRegex = RegExp(
          r'(?:pin|c[oó]digo|bloqueo)\s*[:=\-]?\s*([0-9]{3,6})',
          caseSensitive: false,
        );
        final pinMatch = pinRegex.firstMatch(cleanLine);
        if (pinMatch != null) {
          pin = pinMatch.group(1)?.trim();
        }
      }

      // El proveedor se mantiene 100% manual por el usuario y nunca se sobreescribe
    }

    // Si la clave no se encontró con prefijo pero hay formato "correo:clave" o "correo / clave"
    if (clave == null && correo != null) {
      final sepRegex = RegExp(RegExp.escape(correo) + r'\s*[:|\/,\-]\s*([^\s\r\n]+)');
      final sepMatch = sepRegex.firstMatch(text);
      if (sepMatch != null) {
        clave = sepMatch.group(1)?.trim();
      }
    }

    return SmartParsedResult(
      correo: correo,
      clave: clave,
      perfil: perfil,
      pin: pin,
      servicio: servicio,
      proveedor: proveedor,
      fechaVencimiento: fechaVencimiento,
      textoOriginal: text,
    );
  }
}
