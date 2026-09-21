import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/streaming_controller.dart';
import '../../models/client_model.dart';
import '../../services/cloud_sync_service.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// [VISTA] ClientsScreen — Gestión de clientes (Nombre + Teléfono)
/// ============================================================================
class ClientsScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final StreamingController? streamingController;

  const ClientsScreen({
    Key? key,
    required this.onOpenDrawer,
    this.streamingController,
  }) : super(key: key);

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<ClientModel> _clientes = [];
  bool _loading = true;
  String _busqueda = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ClientsService.notifier.addListener(_onServiceChanged);
    widget.streamingController?.addListener(_onServiceChanged);
    _cargar();
  }

  @override
  void dispose() {
    ClientsService.notifier.removeListener(_onServiceChanged);
    widget.streamingController?.removeListener(_onServiceChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) _cargar();
  }

  Future<void> _cargar() async {
    final lista = await ClientsService.getAll();

    if (mounted) {
      setState(() {
        _clientes = lista..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        _loading = false;
      });
    }
  }

  List<ClientModel> get _filtrados {
    if (_busqueda.isEmpty) return _clientes;
    final q = _busqueda.toLowerCase();
    return _clientes.where((c) =>
        c.nombre.toLowerCase().contains(q) || c.telefono.contains(q)).toList();
  }

  void _mostrarFormulario({ClientModel? cliente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClienteFormSheet(
        cliente: cliente,
        onGuardar: (nombre, telefono) async {
          if (cliente == null) {
            await ClientsService.add(nombre, telefono);
          } else {
            await ClientsService.update(cliente.copyWith(nombre: nombre, telefono: telefono));
          }
          await _cargar();
          if (widget.streamingController != null) {
            CloudSyncService.triggerAutoSync(
              accounts: widget.streamingController!.accounts,
              clients: _clientes,
            );
          }
        },
      ),
    );
  }

  Future<void> _eliminar(ClientModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar cliente', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('¿Eliminar a "${c.nombre}"?\nSus pantallas no se borrarán.', style: const TextStyle(color: AppTheme.textSecondary)),
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
      await ClientsService.delete(c.id);
      await _cargar();
      if (widget.streamingController != null) {
        CloudSyncService.triggerAutoSync(
          accounts: widget.streamingController!.accounts,
          clients: _clientes,
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
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
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
                      const Text('Clientes',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                      Text('${_clientes.length} registrados',
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
                  hintText: 'Buscar por nombre o teléfono...',
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
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _ClienteTile(
                            cliente: filtrados[i],
                            onEditar: () => _mostrarFormulario(cliente: filtrados[i]),
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
        child: const Icon(Icons.people_outline_rounded, color: AppTheme.textMuted, size: 42),
      ),
      const SizedBox(height: 16),
      const Text('Sin clientes registrados', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Toca el botón + para agregar tu primer cliente', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
    ]),
  );
}

class _ClienteTile extends StatelessWidget {
  final ClientModel cliente;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  const _ClienteTile({required this.cliente, required this.onEditar, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final initials = cliente.nombre.isNotEmpty
        ? cliente.nombre.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';
    return Material(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onEditar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.netflixRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(initials, style: const TextStyle(color: AppTheme.netflixRed, fontSize: 14, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cliente.nombre, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.phone_rounded, color: AppTheme.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      cliente.telefono.isEmpty ? 'Sin teléfono' : cliente.telefono,
                      style: TextStyle(color: cliente.telefono.isEmpty ? AppTheme.textMuted : AppTheme.textSecondary, fontSize: 12),
                    ),
                  ]),
                ]),
              ),
              if (cliente.telefono.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textMuted),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: cliente.telefono));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Copiado: ${cliente.telefono}'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.netflixRed),
                onPressed: onEliminar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClienteFormSheet extends StatefulWidget {
  final ClientModel? cliente;
  final Future<void> Function(String nombre, String telefono) onGuardar;
  const _ClienteFormSheet({this.cliente, required this.onGuardar});

  @override
  State<_ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends State<_ClienteFormSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.cliente?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: widget.cliente?.telefono ?? '');
  }

  @override
  void dispose() { _nombreCtrl.dispose(); _telefonoCtrl.dispose(); super.dispose(); }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    await widget.onGuardar(_nombreCtrl.text, _telefonoCtrl.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF18181E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            Text(widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _campo(_nombreCtrl, 'Nombre completo', Icons.person_rounded, TextInputType.name),
            const SizedBox(height: 12),
            _campo(_telefonoCtrl, 'Teléfono / WhatsApp', Icons.phone_rounded, TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.netflixRed, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                ),
                child: _guardando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.cliente == null ? 'AGREGAR CLIENTE' : 'GUARDAR CAMBIOS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon, TextInputType type,
      {List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: type == TextInputType.name ? TextCapitalization.words : TextCapitalization.none,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        filled: true, fillColor: AppTheme.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
      ),
    );
  }
}

/// ============================================================================
/// [WIDGET] ClientSelectorDialog — Selector modal al vender pantalla
/// ============================================================================
class ClientSelectorDialog extends StatefulWidget {
  const ClientSelectorDialog({Key? key}) : super(key: key);

  static Future<ClientModel?> mostrar(BuildContext context) =>
      showModalBottomSheet<ClientModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ClientSelectorDialog(),
      );

  @override
  State<ClientSelectorDialog> createState() => _ClientSelectorDialogState();
}

class _ClientSelectorDialogState extends State<ClientSelectorDialog> {
  List<ClientModel> _clientes = [];
  bool _loading = true;
  String _busqueda = '';
  bool _creandoNuevo = false;
  final _searchCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ClientsService.notifier.addListener(_onChanged);
    _cargar();
  }

  @override
  void dispose() {
    ClientsService.notifier.removeListener(_onChanged);
    _searchCtrl.dispose();
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) _cargar();
  }

  Future<void> _cargar() async {
    final lista = await ClientsService.getAll();
    if (mounted) setState(() { _clientes = lista; _loading = false; });
  }

  List<ClientModel> get _filtrados {
    if (_busqueda.isEmpty) return _clientes;
    final q = _busqueda.toLowerCase();
    return _clientes.where((c) => c.nombre.toLowerCase().contains(q) || c.telefono.contains(q)).toList();
  }

  Future<void> _crearYSeleccionar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    final nuevo = await ClientsService.add(_nombreCtrl.text, _telefonoCtrl.text);
    if (mounted) Navigator.pop(context, nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF18181E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
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
                const Text('Seleccionar Cliente', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
                TextButton.icon(
                  onPressed: () => setState(() => _creandoNuevo = !_creandoNuevo),
                  icon: Icon(_creandoNuevo ? Icons.list_rounded : Icons.person_add_rounded, size: 16),
                  label: Text(_creandoNuevo ? 'Ver lista' : 'Nuevo'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.netflixRed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_creandoNuevo) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                _campoRapido(_nombreCtrl, 'Nombre del cliente', Icons.person_rounded, TextInputType.name),
                const SizedBox(height: 10),
                _campoRapido(_telefonoCtrl, 'Teléfono / WhatsApp', Icons.phone_rounded, TextInputType.phone),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 46,
                  child: ElevatedButton(
                    onPressed: _crearYSeleccionar,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.netflixRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('CREAR Y SELECCIONAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar cliente...', hintStyle: const TextStyle(color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                  filled: true, fillColor: AppTheme.cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.netflixRed, strokeWidth: 2))
                  : filtrados.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.people_outline_rounded, color: AppTheme.textMuted, size: 36),
                          const SizedBox(height: 10),
                          const Text('No hay clientes', style: TextStyle(color: AppTheme.textMuted)),
                          TextButton(
                            onPressed: () => setState(() => _creandoNuevo = true),
                            child: const Text('Crear nuevo →', style: TextStyle(color: AppTheme.netflixRed)),
                          ),
                        ]))
                      : ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final c = filtrados[i];
                            final initials = c.nombre.isNotEmpty
                                ? c.nombre.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join() : '?';
                            return Material(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => Navigator.pop(context, c),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(children: [
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(color: AppTheme.netflixRed.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                      child: Center(child: Text(initials, style: const TextStyle(color: AppTheme.netflixRed, fontSize: 13, fontWeight: FontWeight.w900))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(c.nombre, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                                      if (c.telefono.isNotEmpty)
                                        Text(c.telefono, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                    ])),
                                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _campoRapido(TextEditingController ctrl, String hint, IconData icon, TextInputType type) {
    return TextField(
      controller: ctrl, keyboardType: type,
      textCapitalization: type == TextInputType.name ? TextCapitalization.words : TextCapitalization.none,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: hint, labelStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
        filled: true, fillColor: AppTheme.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed, width: 1.5)),
      ),
    );
  }
}
