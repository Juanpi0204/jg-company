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
  static String _normalizarTexto(String s) {
    return s.toLowerCase()
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('0', 'o')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('@', 'a');
  }

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

    // 0. Pre-procesamiento de limpieza:
    // a. Eliminar caracteres invisibles que insertan WhatsApp y teclados móviles al copiar
    //    (\u200E LTR mark, \u200F RTL mark, \u200B zero-width space, \uFEFF no-break space)
    String cleanText = text
        .replaceAll('\u200E', '')
        .replaceAll('\u200F', '')
        .replaceAll('\u200B', '')
        .replaceAll('\uFEFF', '')
        .replaceAll('\u00A0', ' ')
        .replaceAll('➕', '+')
        .replaceAll('＋', '+')
        .replaceAll('﹢', '+')
        .replaceAll(RegExp(r'%2[bB]'), '+');

    // b. Corregir correos con espacios accidentales alrededor del '+' o del '@'
    //    Ejemplos típicos: "camata323 + hfj647@zohomail.com" -> "camata323+hfj647@zohomail.com"
    cleanText = cleanText.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9._%+-]+)\s*\+\s*([a-zA-Z0-9._%+-]+)\s*@\s*([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'),
      (m) => '${m[1]}+${m[2]}@${m[3]}',
    );
    cleanText = cleanText.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9._%+-]+)\s*@\s*([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'),
      (m) => '${m[1]}@${m[2]}',
    );

    final emailRegex = RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}');
    final emailLabeledRegex = RegExp(
      r'(?:correo|email|e-mail|mail|cuenta|user|usuario)\s*[:=\-👉▶️➡️📧]?\s*([a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,})',
      caseSensitive: false,
    );

    // 0. Detectar si el texto contiene un reemplazo o garantía (cuenta dañada reemplazada por nueva)
    // Si es así, priorizamos el bloque de texto que viene a partir de la indicación de reemplazo.
    String textToParse = cleanText;
    final lowerTotal = cleanText.toLowerCase();
    final indicators = [
      'reemplazo',
      'garantí',
      'garanti',
      'cambio por',
      'nueva cuenta',
      'nuevo correo',
      'actualización de cuenta',
      'actualizacion de cuenta',
    ];
    int bestSplitIdx = -1;
    for (final ind in indicators) {
      final idx = lowerTotal.lastIndexOf(ind);
      if (idx > bestSplitIdx) {
        bestSplitIdx = idx;
      }
    }

    if (bestSplitIdx != -1) {
      final sub = cleanText.substring(bestSplitIdx);
      if (emailRegex.hasMatch(sub) ||
          emailLabeledRegex.hasMatch(sub) ||
          RegExp(r'(?:clave|password|pass)\s*[:=]', caseSensitive: false).hasMatch(sub)) {
        textToParse = sub;
      }
    }

    // 1. Detectar Correo Electrónico
    // Prioridad 1: Etiqueta explícita en textToParse (CORREO:, EMAIL:, CUENTA:)
    final labeledMatches = emailLabeledRegex.allMatches(textToParse).toList();
    if (labeledMatches.isNotEmpty) {
      correo = labeledMatches.last.group(1)?.trim();
    } else {
      // Prioridad 2: Etiqueta explícita en el texto general
      final labeledMatchesOrig = emailLabeledRegex.allMatches(cleanText).toList();
      if (labeledMatchesOrig.isNotEmpty) {
        correo = labeledMatchesOrig.last.group(1)?.trim();
      } else {
        // Prioridad 3: Correo dentro de textToParse (el último si hay varios)
        final emailsInSub = emailRegex.allMatches(textToParse).toList();
        if (emailsInSub.isNotEmpty) {
          correo = emailsInSub.last.group(0)?.trim();
        } else {
          // Prioridad 4: Último correo en el texto completo
          final allEmails = emailRegex.allMatches(cleanText).toList();
          if (allEmails.isNotEmpty) {
            correo = allEmails.last.group(0)?.trim();
          }
        }
      }
    }

    // Normalizar correo si fue encontrado
    if (correo != null) {
      correo = correo
          .replaceAll(' ', '')
          .replaceAll('➕', '+')
          .replaceAll('＋', '+')
          .replaceAll('﹢', '+')
          .replaceAll(RegExp(r'%2[bB]'), '+')
          .trim();
    }

    // Dividir en líneas para análisis por contexto
    // Usamos textToParse primero; si falta algún campo, complementamos con cleanText
    final lines = textToParse.split(RegExp(r'[\r\n]+'));

    for (var line in lines) {
      final cleanLine = line.trim();

      // 2. Detectar Servicio (normalizando leetspeak como N3TFLIX, D1SNEY, etc.)
      if (servicio == null) {
        final norm = _normalizarTexto(cleanLine);
        if (norm.contains('netflix') || norm.contains('netflx') || norm.contains('neflix')) {
          servicio = 'NETFLIX PA';
        } else if (norm.contains('prime') || norm.contains('amazon')) {
          servicio = 'PRIME VIDEO PA';
        } else if (norm.contains('disney')) {
          servicio = 'DISNEY+ PA';
        } else if (norm.contains('max') || norm.contains('hbo')) {
          servicio = 'MAX PA';
        } else if (norm.contains('spotify')) {
          servicio = 'SPOTIFY FAMILIAR';
        } else if (norm.contains('crunchyroll') || norm.contains('crunchy')) {
          servicio = 'CRUNCHYROLL';
        }
      }

      // 3. Detectar Contraseña / Clave
      // Solo líneas con separador EXPLÍCITO (clave: valor, clave= valor)
      // Esto evita capturar "actualización de clave🍿"
      final claveConSeparadorRegex = RegExp(
        r'(?:clave|password|pass|contrase[ñn]a|pwd)\s*[:=]\s*([^\s,;]+)',
        caseSensitive: false,
      );
      final claveMatch = claveConSeparadorRegex.firstMatch(cleanLine);
      if (claveMatch != null) {
        final candidata = claveMatch.group(1)?.trim() ?? '';
        if (candidata.isNotEmpty && candidata.length >= 3) {
          clave = candidata;
        }
      }

      // 4. Detectar Perfil
      final perfilRegex = RegExp(
        r'(?:perfil|pantalla|screen|profile)\s*[:=\-]?\s*([0-9a-zA-Z]+)',
        caseSensitive: false,
      );
      final perfilMatch = perfilRegex.firstMatch(cleanLine);
      if (perfilMatch != null) {
        perfil = perfilMatch.group(1)?.trim();
      }

      // 5. Detectar PIN
      final pinRegex = RegExp(
        r'(?:pin|c[oó]digo|bloqueo)\s*[:=\-]?\s*([0-9]{3,6})',
        caseSensitive: false,
      );
      final pinMatch = pinRegex.firstMatch(cleanLine);
      if (pinMatch != null) {
        pin = pinMatch.group(1)?.trim();
      }
    }

    // Si algún dato faltó en textToParse, buscar en las líneas del texto completo
    if (servicio == null || clave == null || perfil == null || pin == null) {
      final origLines = text.split(RegExp(r'[\r\n]+'));
      for (var line in origLines) {
        final cleanLine = line.trim();

        if (servicio == null) {
          final norm = _normalizarTexto(cleanLine);
          if (norm.contains('netflix') || norm.contains('netflx') || norm.contains('neflix')) {
            servicio = 'NETFLIX PA';
          } else if (norm.contains('prime') || norm.contains('amazon')) {
            servicio = 'PRIME VIDEO PA';
          } else if (norm.contains('disney')) {
            servicio = 'DISNEY+ PA';
          } else if (norm.contains('max') || norm.contains('hbo')) {
            servicio = 'MAX PA';
          } else if (norm.contains('spotify')) {
            servicio = 'SPOTIFY FAMILIAR';
          } else if (norm.contains('crunchyroll') || norm.contains('crunchy')) {
            servicio = 'CRUNCHYROLL';
          }
        }

        if (clave == null) {
          final claveConSeparadorRegex = RegExp(
            r'(?:clave|password|pass|contrase[ñn]a|pwd)\s*[:=]\s*([^\s,;]+)',
            caseSensitive: false,
          );
          final claveMatch = claveConSeparadorRegex.firstMatch(cleanLine);
          if (claveMatch != null) {
            final candidata = claveMatch.group(1)?.trim() ?? '';
            if (candidata.isNotEmpty && candidata.length >= 3) {
              clave = candidata;
            }
          }
        }

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
      }
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
