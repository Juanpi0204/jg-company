import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/streaming_controller.dart';
import '../../models/provider_model.dart';
import '../../services/cloud_sync_service.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA] ProvidersScreen — Directorio de Proveedores de Streaming
/// ============================================================================
/// Permite gestionar proveedores mayoristas (Nombre, WhatsApp de Soporte, Notas):
/// - DIGITAL HOUSE, S.G.R STREAMING, PUNTACANA, DISPONIBLES ALI, etc.
/// - Editar datos y teléfono de soporte técnico
/// - Abrir chat de WhatsApp directo con el proveedor
/// - Sincronizar automáticamente en la nube (MongoDB Atlas)
/// ============================================================================
class ProvidersScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final StreamingController? streamingController;

  const ProvidersScreen({
    Key? key,
    required this.onOpenDrawer,
    this.streamingController,
  }) : super(key: key);

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  List<ProviderModel> _proveedores = [];
  bool _loading = true;
  String _busqueda = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ProvidersService.notifier.addListener(_onServiceChanged);
    _cargar();
  }

  @override
  void dispose() {
    ProvidersService.notifier.removeListener(_onServiceChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) _cargar();
  }

  Future<void> _cargar() async {
    final lista = await ProvidersService.getAll();
    if (mounted) {
      setState(() {
        _proveedores = lista..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        _loading = false;
      });
    }
  }

  List<ProviderModel> get _filtrados {
    if (_busqueda.isEmpty) return _proveedores;
    final q = _busqueda.toLowerCase();
    return _proveedores.where((p) =>
        p.nombre.toLowerCase().contains(q) ||
        p.telefono.contains(q) ||
        p.notas.toLowerCase().contains(q)).toList();
  }

  void _mostrarFormulario({ProviderModel? proveedor}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProviderFormSheet(
        proveedor: proveedor,
        onGuardar: (nombre, telefono, notas) async {
          if (proveedor == null) {
            await ProvidersService.add(nombre, telefono, notas: notas);
          } else {
            await ProvidersService.update(proveedor.copyWith(
              nombre: nombre,
              telefono: telefono,
              notas: notas,
            ));
          }
          await _cargar();
          if (widget.streamingController != null) {
            CloudSyncService.triggerAutoSync(
              accounts: widget.streamingController!.accounts,
              providers: _proveedores,
            );
          }
        },
      ),
    );
  }

  Future<void> _eliminar(ProviderModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar proveedor', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('¿Eliminar al proveedor "${p.nombre}"?\nLas pantallas asociadas conservarán el nombre.',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.netflixRed, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ProvidersService.delete(p.id);
      await _cargar();
      if (widget.streamingController != null) {
        CloudSyncService.triggerAutoSync(
          accounts: widget.streamingController!.accounts,
          providers: _proveedores,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: AppTheme.netflixRed,
        child: const Icon(Icons.add_business_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Proveedores',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                      Text('${_proveedores.length} registrados (Soporte técnico)',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, teléfono o notas...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                  suffixIcon: _busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                          onPressed: () { _searchCtrl.clear(); setState(() => _busqueda = ''); },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.netflixRed, strokeWidth: 2))
                  : filtrados.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtrados.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _ProviderTile(
                            proveedor: filtrados[i],
                            onEditar: () => _mostrarFormulario(proveedor: filtrados[i]),
                            onEliminar: () => _eliminar(filtrados[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.cardBg, shape: BoxShape.circle),
        child: const Icon(Icons.storefront_outlined, color: AppTheme.textMuted, size: 42),
      ),
      const SizedBox(height: 16),
      const Text('Sin proveedores registrados', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Toca el botón + para agregar tu primer proveedor', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
    ]),
  );
}

class _ProviderTile extends StatelessWidget {
  final ProviderModel proveedor;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  const _ProviderTile({required this.proveedor, required this.onEditar, required this.onEliminar});

  void _abrirWhatsAppSoporte(BuildContext context) async {
    final cleanPhone = proveedor.telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este proveedor no tiene número de WhatsApp registrado'),
          backgroundColor: AppTheme.warningAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String phoneFormatted = cleanPhone;
    if (phoneFormatted.length == 10 && phoneFormatted.startsWith('3')) {
      phoneFormatted = '57$phoneFormatted';
    }

    final url = Uri.parse('https://wa.me/$phoneFormatted?text=${Uri.encodeComponent('Hola, solicito soporte técnico para servicios de JG COMPANY S.A.S')}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final initials = proveedor.nombre.isNotEmpty
        ? proveedor.nombre.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'PR';

    return Material(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEditar,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.purpleAccent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(color: AppTheme.purpleAccent, fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proveedor.nombre,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.support_agent_rounded, color: AppTheme.successGreen, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              proveedor.telefono.isEmpty ? 'Sin WhatsApp de soporte' : proveedor.telefono,
                              style: TextStyle(
                                color: proveedor.telefono.isEmpty ? AppTheme.textMuted : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (proveedor.telefono.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                      tooltip: 'Abrir WhatsApp de soporte',
                      onPressed: () => _abrirWhatsAppSoporte(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textMuted),
                      tooltip: 'Copiar número',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: proveedor.telefono));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Copiado: ${proveedor.telefono}'),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ));
                      },
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                    tooltip: 'Editar proveedor',
                    onPressed: onEditar,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.netflixRed),
                    tooltip: 'Eliminar proveedor',
                    onPressed: onEliminar,
                  ),
                ],
              ),
              if (proveedor.notas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    proveedor.notas,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderFormSheet extends StatefulWidget {
  final ProviderModel? proveedor;
  final Future<void> Function(String nombre, String telefono, String notas) onGuardar;
  const _ProviderFormSheet({this.proveedor, required this.onGuardar});

  @override
  State<_ProviderFormSheet> createState() => _ProviderFormSheetState();
}

class _ProviderFormSheetState extends State<_ProviderFormSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _notasCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.proveedor?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: widget.proveedor?.telefono ?? '');
    _notasCtrl = TextEditingController(text: widget.proveedor?.notas ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del proveedor es obligatorio'),
          backgroundColor: AppTheme.netflixRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _guardando = true);
    await widget.onGuardar(nombre, _telefonoCtrl.text.trim(), _notasCtrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.proveedor != null;
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppTheme.borderSubtle, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.purpleAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppTheme.purpleAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor de Streaming',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Nombre del Proveedor (ej. DIGITAL HOUSE)',
              labelStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.business_rounded, color: AppTheme.textMuted, size: 20),
              filled: true, fillColor: AppTheme.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'WhatsApp de Soporte Técnico (ej. 3001234567)',
              labelStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.support_agent_rounded, color: AppTheme.successGreen, size: 20),
              filled: true, fillColor: AppTheme.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notasCtrl,
            maxLines: 2,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Notas / Servicios que vende (opcional)',
              labelStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.textMuted, size: 20),
              filled: true, fillColor: AppTheme.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.netflixRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(esEdicion ? 'Guardar Cambios' : 'Registrar Proveedor', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// [MODAL / DIALOG] ProviderSelectorDialog — Selector modal al crear/editar pantalla
/// ============================================================================
class ProviderSelectorDialog extends StatefulWidget {
  const ProviderSelectorDialog({Key? key}) : super(key: key);

  static Future<ProviderModel?> mostrar(BuildContext context) =>
      showModalBottomSheet<ProviderModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ProviderSelectorDialog(),
      );

  @override
  State<ProviderSelectorDialog> createState() => _ProviderSelectorDialogState();
}

class _ProviderSelectorDialogState extends State<ProviderSelectorDialog> {
  List<ProviderModel> _proveedores = [];
  bool _loading = true;
  String _busqueda = '';
  bool _creandoNuevo = false;
  final _searchCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ProvidersService.notifier.addListener(_onChanged);
    _cargar();
  }

  @override
  void dispose() {
    ProvidersService.notifier.removeListener(_onChanged);
    _searchCtrl.dispose();
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) _cargar();
  }

  Future<void> _cargar() async {
    final lista = await ProvidersService.getAll();
    if (mounted) setState(() { _proveedores = lista; _loading = false; });
  }

  List<ProviderModel> get _filtrados {
    if (_busqueda.isEmpty) return _proveedores;
    final q = _busqueda.toLowerCase();
    return _proveedores.where((p) =>
        p.nombre.toLowerCase().contains(q) ||
        p.telefono.contains(q)).toList();
  }

  Future<void> _crearYSeleccionar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    final nuevo = await ProvidersService.add(_nombreCtrl.text, _telefonoCtrl.text);
    if (mounted) Navigator.pop(context, nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF18181E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seleccionar Proveedor',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
                  TextButton.icon(
                    onPressed: () => setState(() => _creandoNuevo = !_creandoNuevo),
                    icon: Icon(_creandoNuevo ? Icons.list_rounded : Icons.add_business_rounded, size: 16),
                    label: Text(_creandoNuevo ? 'Ver lista' : '+ Nuevo'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.netflixRed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_creandoNuevo) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TextField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Nombre del proveedor',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.business_rounded, color: AppTheme.textMuted, size: 20),
                        filled: true, fillColor: AppTheme.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'WhatsApp de soporte técnico',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.support_agent_rounded, color: AppTheme.successGreen, size: 20),
                        filled: true, fillColor: AppTheme.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _crearYSeleccionar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.netflixRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Guardar y Seleccionar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF24242E), height: 24),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: InputDecoration(
                  hintText: 'Buscar proveedor...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                  filled: true, fillColor: AppTheme.cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.netflixRed, strokeWidth: 2))
                  : filtrados.isEmpty
                      ? const Center(child: Text('No hay proveedores encontrados', style: TextStyle(color: AppTheme.textMuted)))
                      : ListView.builder(
                          controller: ctrl,
                          itemCount: filtrados.length,
                          itemBuilder: (_, i) {
                            final p = filtrados[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.purpleAccent.withOpacity(0.2),
                                child: Text(
                                  p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : 'P',
                                  style: const TextStyle(color: AppTheme.purpleAccent, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(p.nombre, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                p.telefono.isNotEmpty ? 'WhatsApp: ${p.telefono}' : 'Sin número',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                              onTap: () => Navigator.pop(context, p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
