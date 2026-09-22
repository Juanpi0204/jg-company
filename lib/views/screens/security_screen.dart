import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../controllers/streaming_controller.dart';
import '../../models/app_settings.dart';
import '../../models/client_model.dart';
import '../../models/provider_model.dart';
import '../../models/credit_card_model.dart';
import '../../models/debt_model.dart';
import '../../services/cloud_sync_service.dart';
import '../theme/app_theme.dart';
import 'lock_screen.dart';

/// ============================================================================
/// [VISTA / PANTALLA] SecurityScreen — Seguridad, Perfil & Nube MongoDB Atlas
/// ============================================================================
class SecurityScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final StreamingController? streamingController;

  const SecurityScreen({
    Key? key,
    required this.onOpenDrawer,
    this.streamingController,
  }) : super(key: key);

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  List<BiometricType> _biometrics = [];
  bool _loading = true;
  String _nombre = '';

  // Estado MongoDB Atlas
  bool _mongoConfigured = false;
  bool _autoSyncEnabled = true;
  DateTime? _lastSyncDate;
  bool _syncingNow = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarMongoConfig();
    AppSettings.getNombre().then((n) { if (mounted) setState(() => _nombre = n); });

    CloudSyncService.lastSyncNotifier.addListener(_onSyncUpdated);
    CloudSyncService.statusNotifier.addListener(_onSyncStatusChanged);
  }

  @override
  void dispose() {
    CloudSyncService.lastSyncNotifier.removeListener(_onSyncUpdated);
    CloudSyncService.statusNotifier.removeListener(_onSyncStatusChanged);
    super.dispose();
  }

  void _onSyncUpdated() {
    if (mounted) setState(() => _lastSyncDate = CloudSyncService.lastSyncNotifier.value);
  }

  void _onSyncStatusChanged() {
    if (mounted) {
      setState(() {
        _syncingNow = CloudSyncService.statusNotifier.value == SyncStatus.syncing;
      });
    }
  }

  Future<void> _cargarMongoConfig() async {
    final configured = await CloudSyncService.isConfigured();
    final auto = await CloudSyncService.isAutoSyncEnabled();
    final last = await CloudSyncService.getLastSync();
    if (mounted) {
      setState(() {
        _mongoConfigured = configured;
        _autoSyncEnabled = auto;
        _lastSyncDate = last;
      });
    }
  }

  Future<void> _sincronizarAhora() async {
    setState(() => _syncingNow = true);
    final clientes = await ClientsService.getAll();
    final proveedores = await ProvidersService.getAll();
    final tarjetas = await CreditCardsService.getAll();
    final deudas = await DebtsService.getAll();
    final ok = await CloudSyncService.syncToCloud(
      accounts: widget.streamingController?.accounts ?? [],
      clients: clientes,
      providers: proveedores,
      creditCards: tarjetas,
      debts: deudas,
    );
    setState(() => _syncingNow = false);
    _snack(
      ok ? '✅ Respaldo completo en MongoDB Atlas (Pantallas, Tarjetas, Deudas)' : '❌ Error al sincronizar. Revisa tu conexión.',
      ok ? const Color(0xFF00ED64) : AppTheme.netflixRed,
    );
  }

  Future<void> _cargar() async {
    final enabled   = await BiometricService.isBiometricEnabled();
    final available = await BiometricService.isAvailable();
    final types     = await BiometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _biometricEnabled   = enabled;
        _biometricAvailable = available;
        _biometrics         = types;
        _loading            = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Pedir autenticación antes de activar, para verificar que funciona
      final ok = await BiometricService.authenticate();
      if (!ok) {
        if (mounted) {
          _snack('No se pudo verificar tu identidad. Intenta de nuevo.', AppTheme.netflixRed);
        }
        return;
      }
    }
    await BiometricService.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
    _snack(
      value ? '✅ Face ID activado. Se pedirá al abrir la app.' : 'Face ID desactivado.',
      value ? AppTheme.successGreen : AppTheme.warningAmber,
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _cambiarNombre() async {
    final ctrl = TextEditingController(text: _nombre);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tu nombre', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Este nombre aparece en el saludo del dashboard.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Escribe tu nombre...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.textMuted, size: 20),
                filled: true,
                fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await AppSettings.setNombre(ctrl.text.trim());
                if (mounted) setState(() => _nombre = ctrl.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.netflixRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarConfiguracionPrecios() async {
    final costos = await AppSettings.getCostos();
    final ventas = await AppSettings.getVentas();

    final netflixCostoCtrl = TextEditingController(
      text: (costos['NETFLIX PA'] ?? 11000).toStringAsFixed(0),
    );
    final netflixVentaCtrl = TextEditingController(
      text: (ventas['NETFLIX PA'] ?? 14000).toStringAsFixed(0),
    );

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF18181E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.price_change_rounded, color: AppTheme.netflixRed, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Precios por Defecto',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Ajusta los precios base en caso de alzas de tarifas del proveedor o venta al público.',
                style: TextStyle(color: Color(0xFF888899), fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Tarjeta Netflix
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.netflixRed.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tv_rounded, color: AppTheme.netflixRed, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'NETFLIX PA (Por Defecto)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: netflixCostoCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Costo Base (\$)',
                              labelStyle: const TextStyle(color: Color(0xFF888899), fontSize: 12),
                              hintText: '11000',
                              filled: true,
                              fillColor: const Color(0xFF141418),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: netflixVentaCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Venta Base (\$)',
                              labelStyle: const TextStyle(color: Color(0xFF888899), fontSize: 12),
                              hintText: '14000',
                              filled: true,
                              fillColor: const Color(0xFF141418),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.netflixRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final cNet = double.tryParse(netflixCostoCtrl.text) ?? 11000.0;
                    final vNet = double.tryParse(netflixVentaCtrl.text) ?? 14000.0;

                    costos['NETFLIX PA'] = cNet;
                    ventas['NETFLIX PA'] = vNet;

                    await AppSettings.setCostos(costos);
                    await AppSettings.setVentas(ventas);

                    if (ctx.mounted) Navigator.pop(ctx);
                    _snack('✅ Precios de Netflix actualizados', AppTheme.successGreen);
                  },
                  child: const Text(
                    'GUARDAR CAMBIOS DE PRECIOS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarConfiguracionMongo() async {
    final cfg = await CloudSyncService.getConfig();
    final connStringCtrl = TextEditingController(text: cfg['connectionString']);
    final endpointCtrl = TextEditingController(text: cfg['endpoint']);
    final apiKeyCtrl = TextEditingController(text: cfg['apiKey']);
    final clusterCtrl = TextEditingController(text: cfg['cluster']);
    final databaseCtrl = TextEditingController(text: cfg['database']);

    bool testing = false;
    String? testMsg;
    bool? testSuccess;
    bool showAdvanced = cfg['endpoint']!.isNotEmpty || cfg['apiKey']!.isNotEmpty;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.96,
          minChildSize: 0.5,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF16161D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: ListView(
              controller: scrollCtrl,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.cloud_sync_rounded, color: Color(0xFF00ED64), size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Conectar MongoDB (Nube)',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Conecta tu cluster de Atlas o Compass para auto-guardar tus pantallas, clientes, proveedores, tarjetas y deudas en tiempo real y al salir de la app.',
                  style: TextStyle(color: Color(0xFF888899), fontSize: 12),
                ),
                const SizedBox(height: 18),

                // Campo principal: Cadena de conexión Compass
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00ED64).withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.vpn_key_rounded, color: Color(0xFF00ED64), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'CADENA DE CONEXIÓN (COMPASS / ATLAS)',
                            style: TextStyle(color: Color(0xFF00ED64), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pega aquí la cadena que te da MongoDB Atlas o Compass.',
                        style: TextStyle(color: Color(0xFF9E9EAA), fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: connStringCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'mongodb+srv://usuario:password@cluster0.abcde.mongodb.net/?retryWrites=true&w=majority',
                          hintStyle: const TextStyle(color: Color(0xFF555566), fontSize: 11),
                          filled: true,
                          fillColor: const Color(0xFF16161F),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00ED64), width: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Base de datos destino
                _inputMongo(
                  label: 'Nombre de la Base de Datos (en tu cluster)',
                  hint: 'jg_company',
                  controller: databaseCtrl,
                  icon: Icons.folder_rounded,
                ),

                const SizedBox(height: 12),

                // Opciones avanzadas toggle
                InkWell(
                  onTap: () => setModalState(() => showAdvanced = !showAdvanced),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(showAdvanced ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF888899), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          showAdvanced ? 'Ocultar opciones avanzadas (Data API)' : 'Opciones avanzadas (MongoDB Data API)',
                          style: const TextStyle(color: Color(0xFF888899), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                if (showAdvanced) ...[
                  const SizedBox(height: 8),
                  _inputMongo(
                    label: 'Data API Endpoint URL',
                    hint: 'https://data.mongodb-api.com/app/.../endpoint/data/v1',
                    controller: endpointCtrl,
                    icon: Icons.link_rounded,
                  ),
                  const SizedBox(height: 10),
                  _inputMongo(
                    label: 'API Key de MongoDB Atlas',
                    hint: 'Tu clave API de Atlas Data API',
                    controller: apiKeyCtrl,
                    icon: Icons.key_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  _inputMongo(
                    label: 'Cluster Name',
                    hint: 'Cluster0',
                    controller: clusterCtrl,
                    icon: Icons.storage_rounded,
                  ),
                ],

                const SizedBox(height: 16),

                // Resultado del test
                if (testMsg != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: testSuccess == true
                          ? const Color(0xFF00ED64).withOpacity(0.12)
                          : AppTheme.netflixRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: testSuccess == true
                            ? const Color(0xFF00ED64).withOpacity(0.3)
                            : AppTheme.netflixRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: testSuccess == true ? const Color(0xFF00ED64) : AppTheme.netflixRed,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            testMsg!,
                            style: TextStyle(
                              color: testSuccess == true ? const Color(0xFF00ED64) : Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Botón Probar Conexión
                OutlinedButton.icon(
                  onPressed: testing ? null : () async {
                    setModalState(() {
                      testing = true;
                      testMsg = null;
                    });
                    final ok = await CloudSyncService.testConnection(
                      testEndpoint: endpointCtrl.text,
                      testApiKey: apiKeyCtrl.text,
                      testCluster: clusterCtrl.text,
                      testDatabase: databaseCtrl.text,
                    );
                    setModalState(() {
                      testing = false;
                      testSuccess = ok;
                      testMsg = ok
                          ? '✅ ¡Conexión exitosa con tu cluster de MongoDB Atlas!'
                          : '❌ No se pudo conectar. Verifica la URL y la API Key.';
                    });
                  },
                  icon: testing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00ED64)))
                      : const Icon(Icons.network_check_rounded, color: Color(0xFF00ED64), size: 18),
                  label: Text(
                    testing ? 'Probando conexión...' : 'PROBAR CONEXIÓN',
                    style: const TextStyle(color: Color(0xFF00ED64), fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00ED64)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 12),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ED64),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await CloudSyncService.saveConfig(
                        connectionString: connStringCtrl.text,
                        endpoint: endpointCtrl.text,
                        apiKey: apiKeyCtrl.text,
                        cluster: clusterCtrl.text,
                        database: databaseCtrl.text,
                      );
                      await _cargarMongoConfig();

                      // Sincronizar de inmediato
                      if (widget.streamingController != null) {
                        CloudSyncService.syncToCloud(accounts: widget.streamingController!.accounts);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                      _snack('✅ Configuración de MongoDB guardada', const Color(0xFF00ED64));
                    },
                    child: const Text('GUARDAR Y ACTIVAR AUTO-SYNC', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputMongo({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFCCCCDD), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF555566), fontSize: 12),
            prefixIcon: Icon(icon, color: const Color(0xFF00ED64), size: 18),
            filled: true,
            fillColor: const Color(0xFF101016),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00ED64))),
          ),
        ),
      ],
    );
  }

  String get _biometricLabel {
    if (_biometrics.contains(BiometricType.face)) return 'Face ID';
    if (_biometrics.contains(BiometricType.fingerprint)) return 'Huella digital';
    if (_biometrics.contains(BiometricType.iris)) return 'Iris';
    return 'Biometría';
  }

  IconData get _biometricIcon {
    if (_biometrics.contains(BiometricType.face)) return Icons.face_retouching_natural_rounded;
    if (_biometrics.contains(BiometricType.fingerprint)) return Icons.fingerprint_rounded;
    return Icons.lock_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── HEADER ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onOpenDrawer,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary, size: 21),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seguridad',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                        Text('Autenticación & Protección',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── CONTENIDO ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.netflixRed))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── ICONO CENTRAL ─────────────────────────────────
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF7C83FD).withOpacity(0.1),
                                    border: Border.all(
                                      color: const Color(0xFF7C83FD).withOpacity(
                                          _biometricEnabled ? 0.6 : 0.2),
                                      width: 2,
                                    ),
                                    boxShadow: _biometricEnabled
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF7C83FD).withOpacity(0.25),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    _biometricIcon,
                                    size: 48,
                                    color: _biometricEnabled
                                        ? const Color(0xFF7C83FD)
                                        : const Color(0xFF555566),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _biometricEnabled
                                      ? '$_biometricLabel activado ✅'
                                      : '$_biometricLabel desactivado',
                                  style: TextStyle(
                                    color: _biometricEnabled
                                        ? AppTheme.successGreen
                                        : AppTheme.textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── TOGGLE PRINCIPAL ──────────────────────────────
                          _sectionLabel('AUTENTICACIÓN BIOMÉTRICA'),
                          const SizedBox(height: 10),

                          if (!_biometricAvailable) ...[
                            _infoCard(
                              icon: Icons.info_outline_rounded,
                              color: AppTheme.infoBlue,
                              title: 'No disponible en este dispositivo',
                              subtitle: 'Face ID y Touch ID requieren hardware biométrico. Funcionará en tu iPhone.',
                            ),
                          ] else ...[
                            _toggleCard(
                              icon: _biometricIcon,
                              color: const Color(0xFF7C83FD),
                              title: 'Activar $_biometricLabel',
                              subtitle: _biometricEnabled
                                  ? 'Se solicitará al abrir JG Company'
                                  : 'La app se abrirá sin autenticación',
                              value: _biometricEnabled,
                              onChanged: _toggleBiometric,
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ── MI PERFIL & CONFIGURACIÓN DE PRECIOS ──────────
                          _sectionLabel('MI PERFIL & CONFIGURACIÓN DE PRECIOS'),
                          const SizedBox(height: 10),

                          _actionCard(
                            icon: Icons.person_rounded,
                            color: AppTheme.netflixRed,
                            title: 'Mi Nombre en la App',
                            subtitle: _nombre.isEmpty ? 'Toca para configurar tu nombre' : _nombre,
                            trailing: const Icon(Icons.edit_rounded, color: AppTheme.netflixRed, size: 18),
                            onTap: _cambiarNombre,
                          ),

                          const SizedBox(height: 10),

                          _actionCard(
                            icon: Icons.price_change_rounded,
                            color: AppTheme.successGreen,
                            title: 'Precios de Servicios (Costo & Venta)',
                            subtitle: 'Configura Netflix (Costo \$11.000 / Venta \$14.000) o alzas de precios',
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                            onTap: _mostrarConfiguracionPrecios,
                          ),

                          const SizedBox(height: 24),

                          // ── OTRAS OPCIONES ────────────────────────────────
                          _sectionLabel('PRIVACIDAD'),
                          const SizedBox(height: 10),

                          _infoCard(
                            icon: Icons.cloud_done_rounded,
                            color: AppTheme.successGreen,
                            title: 'Copia de seguridad en la nube',
                            subtitle: 'Pantallas, clientes, proveedores, tarjetas y deudas respaldados',
                          ),

                          const SizedBox(height: 10),

                          // ── TARJETA INTERACTIVA MONGODB ATLAS ──────────────
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _mongoConfigured
                                    ? const Color(0xFF00ED64).withOpacity(0.3)
                                    : AppTheme.borderSubtle,
                                width: _mongoConfigured ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00ED64).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.cloud_sync_rounded,
                                        color: Color(0xFF00ED64),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'MongoDB Atlas (Nube)',
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _mongoConfigured
                                                ? (_lastSyncDate != null
                                                    ? 'Último respaldo: ${_lastSyncDate!.hour.toString().padLeft(2, '0')}:${_lastSyncDate!.minute.toString().padLeft(2, '0')} • Auto-sync activo'
                                                    : 'Conectado • Esperando primer respaldo')
                                                : 'Conecta tu cluster para auto-guardar en la nube',
                                            style: TextStyle(
                                              color: _mongoConfigured
                                                  ? const Color(0xFF00ED64)
                                                  : AppTheme.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                                      tooltip: 'Configurar conexión',
                                      onPressed: _mostrarConfiguracionMongo,
                                    ),
                                  ],
                                ),
                                if (_mongoConfigured) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _syncBadge('Pantallas'),
                                      _syncBadge('Clientes'),
                                      _syncBadge('Proveedores'),
                                      _syncBadge('Tarjetas'),
                                      _syncBadge('Deudas'),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(color: Color(0xFF242430), height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Auto-guardar en segundo plano',
                                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            'Al detectar cambios y antes de cerrar la app',
                                            style: TextStyle(color: Color(0xFF888899), fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      Switch(
                                        value: _autoSyncEnabled,
                                        activeColor: const Color(0xFF00ED64),
                                        activeTrackColor: const Color(0xFF00ED64).withOpacity(0.3),
                                        inactiveThumbColor: const Color(0xFF555566),
                                        inactiveTrackColor: const Color(0xFF252530),
                                        onChanged: (val) async {
                                          await CloudSyncService.setAutoSyncEnabled(val);
                                          setState(() => _autoSyncEnabled = val);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: _syncingNow ? null : _sincronizarAhora,
                                      icon: _syncingNow
                                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00ED64)))
                                          : const Icon(Icons.sync_rounded, color: Color(0xFF00ED64), size: 16),
                                      label: Text(
                                        _syncingNow ? 'Sincronizando...' : 'Sincronizar ahora con la nube',
                                        style: const TextStyle(color: Color(0xFF00ED64), fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF00ED64)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      onPressed: _mostrarConfiguracionMongo,
                                      icon: const Icon(Icons.add_link_rounded, color: Colors.black, size: 18),
                                      label: const Text(
                                        'CONECTAR CLUSTER ATLAS',
                                        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00ED64),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          _infoCard(
                            icon: Icons.lock_rounded,
                            color: AppTheme.netflixRed,
                            title: 'PIN de respaldo del sistema',
                            subtitle: 'Si Face ID falla, el iPhone pedirá el PIN de desbloqueo del sistema.',
                          ),

                          const SizedBox(height: 90),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _syncBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFF00ED64).withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF00ED64).withOpacity(0.25), width: 0.8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF00ED64),
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppTheme.textMuted.withOpacity(0.7),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
    ),
  );

  Widget _toggleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? color.withOpacity(0.4) : AppTheme.borderSubtle,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.25),
            inactiveThumbColor: const Color(0xFF555566),
            inactiveTrackColor: const Color(0xFF252530),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
