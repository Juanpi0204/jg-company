import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/streaming_account_model.dart';
import '../models/storage_service.dart';

/// ============================================================================
/// [CONTROLADOR] StreamingController
/// ============================================================================
/// Gestiona la lógica de negocio para las cuentas de streaming y clientes:
/// - Filtrado en tiempo real por búsqueda y estado (PAGO, PENDIENTE, VENCIDO).
/// - Operaciones CRUD (Crear, Leer, Actualizar, Eliminar).
/// - Envío automático de credenciales vía WhatsApp.
/// - Copiado rápido al portapapeles.
/// - Notifica a las Vistas cuando los datos cambian mediante ChangeNotifier.
/// ============================================================================
class StreamingController extends ChangeNotifier {
  List<StreamingAccountModel> _accounts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'TODOS'; // 'TODOS', 'PAGO', 'PENDIENTE', 'POR VENCER'
  String _serviceFilter = 'TODOS'; // 'TODOS', 'NETFLIX', 'PRIME VIDEO', etc.

  // Getters para que la Vista lea el estado
  List<StreamingAccountModel> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get serviceFilter => _serviceFilter;

  /// Inicializa cargando las cuentas de la base de datos local
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _accounts = await StorageService.loadAccounts();
    _isLoading = false;
    notifyListeners();
  }

  /// Actualiza el término de búsqueda por cliente, correo o servicio
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Establece el filtro de estado (TODOS, PAGO, PENDIENTE, POR VENCER)
  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  /// Establece el filtro de servicio
  void setServiceFilter(String service) {
    _serviceFilter = service;
    notifyListeners();
  }

  /// Retorna la lista de cuentas filtrada según búsqueda y opciones seleccionadas
  List<StreamingAccountModel> get filteredAccounts {
    return _accounts.where((account) {
      // 1. Filtro de búsqueda por texto
      final matchesSearch = _searchQuery.isEmpty ||
          account.cliente.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          account.cuenta.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          account.servicio.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          account.proveedor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          account.vendedor.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // 2. Filtro de estado y semáforo
      if (_statusFilter == 'ACTIVAS' && !account.esActiva) return false;
      if (_statusFilter == 'POR VENCER' && !account.esPorVencer) return false;
      if (_statusFilter == 'VENCIDAS' && !account.esVencida) return false;
      if (_statusFilter == 'PAGO' && !account.estaPagado) return false;
      if (_statusFilter == 'PENDIENTE' && account.estaPagado) return false;

      // 3. Filtro de servicio
      if (_serviceFilter != 'TODOS') {
        if (!account.servicio.toLowerCase().contains(_serviceFilter.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Agrega una nueva cuenta/pantalla y persiste en almacenamiento local
  Future<void> addAccount(StreamingAccountModel account) async {
    _accounts.insert(0, account);
    await StorageService.saveAccounts(_accounts);
    notifyListeners();
  }

  /// Actualiza una cuenta existente
  Future<void> updateAccount(StreamingAccountModel updated) async {
    final index = _accounts.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _accounts[index] = updated;
      await StorageService.saveAccounts(_accounts);
      notifyListeners();
    }
  }

  /// Renueva una cuenta por 30 días adicionales
  Future<void> renewAccount(String id, BuildContext context) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final renewed = _accounts[index].renovar30Dias();
      _accounts[index] = renewed;
      await StorageService.saveAccounts(_accounts);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.autorenew_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('¡Pantalla de ${renewed.cliente} renovada +30 días!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// Actualiza rápidamente credenciales (ej. cuando el revendedor cambia la clave)
  Future<void> updateCredentials(
    String id, {
    String? cuenta,
    String? clave,
    String? pin,
    String? perfil,
    String? proveedor,
    String? servicio,
  }) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final current = _accounts[index];
      _accounts[index] = current.copyWith(
        cuenta: cuenta ?? current.cuenta,
        clave: clave ?? current.clave,
        pin: pin ?? current.pin,
        perfil: perfil ?? current.perfil,
        proveedor: proveedor ?? current.proveedor,
        servicio: servicio ?? current.servicio,
      );
      await StorageService.saveAccounts(_accounts);
      notifyListeners();
    }
  }

  /// Elimina una cuenta por su ID
  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    await StorageService.saveAccounts(_accounts);
    notifyListeners();
  }

  /// Alterna el estado de pago de una cuenta (PAGO <-> PENDIENTE)
  Future<void> togglePaymentStatus(String id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final current = _accounts[index];
      final newStatus = current.estaPagado ? 'PENDIENTE' : 'PAGO';
      _accounts[index] = current.copyWith(estado: newStatus);
      await StorageService.saveAccounts(_accounts);
      notifyListeners();
    }
  }

  /// Genera y copia el texto con las credenciales al portapapeles del celular
  Future<void> copyCredentials(StreamingAccountModel account, BuildContext context) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final text = '''
🍿 *JG COMPANY S.A.S - DATOS DE TU CUENTA* 🍿
━━━━━━━━━━━━━━━━━━━━
👤 *Cliente:* ${account.cliente}
📺 *Servicio:* ${account.servicio}
📧 *Cuenta:* ${account.cuenta}
🔑 *Clave:* ${account.clave}
🔢 *Perfil:* ${account.perfil}
🔒 *PIN:* ${account.pin.isNotEmpty ? account.pin : 'Sin PIN'}
📅 *Fecha de Compra:* ${dateFormat.format(account.fechaCompra)}
⏳ *Fecha de Vencimiento:* ${dateFormat.format(account.fechaVencimiento)}
━━━━━━━━━━━━━━━━━━━━
¡Gracias por tu compra! Recuerda no modificar datos de otros perfiles.
''';

    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('¡Credenciales copiadas al portapapeles!'),
            ],
          ),
          backgroundColor: const Color(0xFFE50914),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Envía un mensaje formateado directo a WhatsApp con los datos de la cuenta
  Future<void> sendWhatsApp(StreamingAccountModel account) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final message = '''
🍿 *JG COMPANY S.A.S - DATOS DE TU CUENTA* 🍿
━━━━━━━━━━━━━━━━━━━━
Hola *${account.cliente}*, aquí tienes los datos de tu pantalla:

📺 *Servicio:* ${account.servicio}
📧 *Correo:* ${account.cuenta}
🔑 *Contraseña:* ${account.clave}
🔢 *Perfil asignado:* ${account.perfil}
🔒 *PIN de acceso:* ${account.pin.isNotEmpty ? account.pin : 'Sin PIN'}

📅 *Fecha de Vencimiento:* ${dateFormat.format(account.fechaVencimiento)}
━━━━━━━━━━━━━━━━━━━━
¡Disfruta de tu programación favorita! 🎬✨
''';

    await _launchWhatsApp(account.telefono, message);
  }

  /// Envía un recordatorio de vencimiento por WhatsApp (Amarillo / Por Vencer)
  Future<void> sendRenewalReminderWhatsApp(StreamingAccountModel account) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formatoMoneda = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final dias = account.diasRestantes;

    final String tiempoTexto = dias > 0
        ? 'vence en *$dias día(s)* (${dateFormat.format(account.fechaVencimiento)})'
        : dias == 0
            ? 'vence *HOY*'
            : 'ya se encuentra *VENCIDA*';

    final message = '''
⚠️ *JG COMPANY S.A.S - RECORDATORIO DE VENCIMIENTO* ⚠️
━━━━━━━━━━━━━━━━━━━━
Hola *${account.cliente}*, esperamos que estés disfrutando tu servicio.

Te informamos que tu pantalla de *${account.servicio}* (Perfil ${account.perfil}) $tiempoTexto.

💰 *Valor de Renovación:* ${formatoMoneda.format(account.valorVenta)}

¿Deseas renovar tu servicio para continuar sin interrupciones?
Quedamos atentos a tu confirmación para mantener tu perfil activo. 🎬✨
''';

    await _launchWhatsApp(account.telefono, message);
  }

  /// Envía una notificación de cambio de clave por WhatsApp
  Future<void> sendNewPasswordWhatsApp(StreamingAccountModel account) async {
    final message = '''
🔑 *JG COMPANY S.A.S - ACTUALIZACIÓN DE CLAVE* 🔑
━━━━━━━━━━━━━━━━━━━━
Hola *${account.cliente}*, hemos actualizado la clave de acceso a tu pantalla de *${account.servicio}*:

📧 *Correo:* ${account.cuenta}
🔑 *Nueva Contraseña:* ${account.clave}
🔢 *Tu Perfil:* ${account.perfil}
🔒 *PIN:* ${account.pin.isNotEmpty ? account.pin : 'Sin PIN'}

Ya puedes ingresar con esta nueva clave. ¡Disfruta tu contenido! 🍿🎬
''';

    await _launchWhatsApp(account.telefono, message);
  }

  Future<void> _launchWhatsApp(String telefono, String message) async {
    final cleanPhone = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMessage = Uri.encodeComponent(message);

    String targetPhone = cleanPhone;
    if (targetPhone.length == 10 && targetPhone.startsWith('3')) {
      targetPhone = '57$targetPhone';
    }

    Uri url;
    if (targetPhone.isNotEmpty) {
      url = Uri.parse('https://wa.me/$targetPhone?text=$encodedMessage');
    } else {
      url = Uri.parse('https://api.whatsapp.com/send?text=$encodedMessage');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error al abrir WhatsApp: $e');
    }
  }

  /// Lista de servicios únicos disponibles para el filtro
  List<String> get availableServices {
    final set = {'TODOS'};
    for (var acc in _accounts) {
      set.add(acc.servicio);
    }
    return set.toList();
  }
}
