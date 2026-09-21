import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/streaming_account_model.dart';
import '../../controllers/streaming_controller.dart';
import '../../models/app_settings.dart';
import '../../models/client_model.dart';
import '../screens/clients_screen.dart';
import '../theme/app_theme.dart';
import 'smart_paste_dialog.dart';

/// ============================================================================
/// [WIDGET / VISTA] AccountFormModal
/// ============================================================================
/// Modal flotante para crear una nueva cuenta/pantalla o editar una existente.
/// Características:
/// - Campos exactos del Excel de JG COMPANY S.A.S
/// - Cálculo automático de Ganancia en tiempo real mientras escribes los precios
/// - Selector de servicio (Netflix, Prime, etc.) y estado (PAGO, PENDIENTE)
/// - Selector de fechas con autocalculado de 30 días de vigencia
/// ============================================================================
class AccountFormModal extends StatefulWidget {
  final StreamingAccountModel? accountParaEditar;
  final StreamingController controller;

  const AccountFormModal({
    Key? key,
    this.accountParaEditar,
    required this.controller,
  }) : super(key: key);

  @override
  State<AccountFormModal> createState() => _AccountFormModalState();
}

class _AccountFormModalState extends State<AccountFormModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _clienteCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _servicioCtrl;
  late TextEditingController _proveedorCtrl;
  late TextEditingController _cuentaCtrl;
  late TextEditingController _claveCtrl;
  late TextEditingController _perfilCtrl;
  late TextEditingController _pinCtrl;
  late TextEditingController _valorVentaCtrl;
  late TextEditingController _valorCompraCtrl;
  late TextEditingController _vendedorCtrl;
  late TextEditingController _notasCtrl;

  late DateTime _fechaCompra;
  late DateTime _fechaVencimiento;
  String _estado = 'PAGO';

  final List<String> _serviciosSugeridos = [
    'NETFLIX PA',
    'PRIME VIDEO PA',
    'DISNEY+ PA',
    'MAX PA',
    'SPOTIFY FAMILIAR',
    'CRUNCHYROLL',
  ];

  final List<String> _proveedoresSugeridos = [
    'DIGITAL HOUSE',
    'S.G.R STREAMING',
    'PUNTACANA',
    'DISPONIBLES ALI',
  ];

  @override
  void initState() {
    super.initState();
    final acc = widget.accountParaEditar;

    _clienteCtrl = TextEditingController(text: acc?.cliente ?? '');
    _telefonoCtrl = TextEditingController(text: acc?.telefono ?? '');
    _servicioCtrl = TextEditingController(text: acc?.servicio ?? 'NETFLIX PA');
    _proveedorCtrl = TextEditingController(text: acc?.proveedor ?? '');
    _cuentaCtrl = TextEditingController(text: acc?.cuenta ?? '');
    _claveCtrl = TextEditingController(text: acc?.clave ?? '');
    _perfilCtrl = TextEditingController(text: acc?.perfil ?? '1');
    _pinCtrl = TextEditingController(text: acc?.pin ?? '');
    // Netflix por defecto: venta 14000, costo 11000
    _valorVentaCtrl = TextEditingController(text: acc != null ? acc.valorVenta.toStringAsFixed(0) : '14000');
    _valorCompraCtrl = TextEditingController(text: acc != null ? acc.valorCompra.toStringAsFixed(0) : '11000');
    _vendedorCtrl = TextEditingController(text: acc?.vendedor ?? 'JUAN');
    _notasCtrl = TextEditingController(text: acc?.notas ?? '');

    _fechaCompra = acc?.fechaCompra ?? DateTime.now();
    _fechaVencimiento = acc?.fechaVencimiento ?? DateTime.now().add(const Duration(days: 30));
    _estado = acc?.estado ?? 'PAGO';

    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    if (widget.accountParaEditar == null) {
      final nombre = await AppSettings.getNombre();
      final venta = await AppSettings.getVentaParaServicio(_servicioCtrl.text.trim().toUpperCase());
      final costo = await AppSettings.getCostoParaServicio(_servicioCtrl.text.trim().toUpperCase());
      if (mounted) {
        setState(() {
          _vendedorCtrl.text = nombre.toUpperCase();
          _valorVentaCtrl.text = venta.toStringAsFixed(0);
          _valorCompraCtrl.text = costo.toStringAsFixed(0);
        });
      }
    }
  }

  Future<void> _alCambiarServicio(String servicio) async {
    setState(() => _servicioCtrl.text = servicio);
    if (widget.accountParaEditar == null) {
      final venta = await AppSettings.getVentaParaServicio(servicio.trim().toUpperCase());
      final costo = await AppSettings.getCostoParaServicio(servicio.trim().toUpperCase());
      if (mounted) {
        setState(() {
          _valorVentaCtrl.text = venta.toStringAsFixed(0);
          _valorCompraCtrl.text = costo.toStringAsFixed(0);
        });
      }
    }
  }

  Future<void> _seleccionarCliente() async {
    final cliente = await ClientSelectorDialog.mostrar(context);
    if (cliente != null && mounted) {
      setState(() {
        _clienteCtrl.text = cliente.nombre;
        if (cliente.telefono.isNotEmpty) {
          _telefonoCtrl.text = cliente.telefono;
        }
      });
    }
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _telefonoCtrl.dispose();
    _servicioCtrl.dispose();
    _proveedorCtrl.dispose();
    _cuentaCtrl.dispose();
    _claveCtrl.dispose();
    _perfilCtrl.dispose();
    _pinCtrl.dispose();
    _valorVentaCtrl.dispose();
    _valorCompraCtrl.dispose();
    _vendedorCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  double get _gananciaCalculada {
    final venta = double.tryParse(_valorVentaCtrl.text) ?? 0.0;
    final compra = double.tryParse(_valorCompraCtrl.text) ?? 0.0;
    return venta - compra;
  }

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final esEdicion = widget.accountParaEditar != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de arrastre
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Título
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      esEdicion ? 'EDITAR PANTALLA' : 'NUEVA PANTALLA / CLIENTE',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Botón de Pegado Inteligente de WhatsApp
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => SmartPasteDialog(
                        onResult: (result) {
                          setState(() {
                            if (result.correo != null) _cuentaCtrl.text = result.correo!;
                            if (result.clave != null) _claveCtrl.text = result.clave!;
                            if (result.perfil != null) _perfilCtrl.text = result.perfil!;
                            if (result.pin != null) _pinCtrl.text = result.pin!;
                            if (result.servicio != null) _servicioCtrl.text = result.servicio!;
                            if (result.proveedor != null) _proveedorCtrl.text = result.proveedor!;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Datos del proveedor completados automáticamente!'),
                              backgroundColor: AppTheme.netflixRed,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, color: AppTheme.purpleAccent, size: 18),
                  label: const Text('Pegar mensaje del Proveedor (Autocompletar)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.purpleAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 14),

                // Indicador de Ganancia en Tiempo Real
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ganancia Estimada:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '+${formatoMoneda.format(_gananciaCalculada)}',
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sección 1: Datos del Cliente
                _buildSectionHeader('1. DATOS DEL CLIENTE'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarCliente,
                        icon: const Icon(Icons.people_alt_rounded, color: AppTheme.netflixRed, size: 16),
                        label: const Text(
                          'Seleccionar de Clientes o Crear Nuevo',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: AppTheme.netflixRed.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _clienteCtrl,
                  label: 'Nombre Completo del Cliente',
                  icon: Icons.person_outline,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.person_search_rounded, color: AppTheme.netflixRed),
                    tooltip: 'Buscar / Crear en clientes',
                    onPressed: _seleccionarCliente,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa el nombre del cliente' : null,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _telefonoCtrl,
                  label: 'Teléfono / WhatsApp (ej. +57300...)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                // Sección 2: Servicio y Proveedor
                _buildSectionHeader('2. SERVICIO Y PROVEEDOR'),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownOrField(
                        controller: _servicioCtrl,
                        label: 'Servicio',
                        items: _serviciosSugeridos,
                        icon: Icons.tv,
                        onCustomSelected: _alCambiarServicio,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdownOrField(
                        controller: _proveedorCtrl,
                        label: 'Proveedor',
                        items: _proveedoresSugeridos,
                        icon: Icons.business,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sección 3: Credenciales de la Cuenta
                _buildSectionHeader('3. CREDENCIALES DE ACCESO'),
                _buildTextField(
                  controller: _cuentaCtrl,
                  label: 'Correo de la Cuenta',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa el correo' : null,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _claveCtrl,
                  label: 'Contraseña / Clave',
                  icon: Icons.lock_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa la clave' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _perfilCtrl,
                        label: 'N° Perfil (ej. 1, 2)',
                        icon: Icons.person_pin,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _pinCtrl,
                        label: 'PIN (ej. 2030)',
                        icon: Icons.pin_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sección 4: Finanzas y Estado
                _buildSectionHeader('4. PRECIOS Y ESTADO DE PAGO'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _valorVentaCtrl,
                        label: 'Precio Venta (\$)',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _valorCompraCtrl,
                        label: 'Costo Compra (\$)',
                        icon: Icons.money_off,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Estado de Pago (PAGO vs PENDIENTE)
                Row(
                  children: [
                    const Text('Estado de Pago: ', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('PAGO', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _estado == 'PAGO',
                      selectedColor: AppTheme.successGreen.withOpacity(0.25),
                      side: BorderSide(color: _estado == 'PAGO' ? AppTheme.successGreen : AppTheme.borderSubtle),
                      onSelected: (val) => setState(() => _estado = 'PAGO'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('PENDIENTE', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _estado == 'PENDIENTE',
                      selectedColor: AppTheme.warningAmber.withOpacity(0.25),
                      side: BorderSide(color: _estado == 'PENDIENTE' ? AppTheme.warningAmber : AppTheme.borderSubtle),
                      onSelected: (val) => setState(() => _estado = 'PENDIENTE'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sección 5: Fechas
                _buildSectionHeader('5. FECHAS DE COMPRA Y VENCIMIENTO'),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerTile(
                        label: 'Fecha Compra',
                        date: _fechaCompra,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaCompra,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() {
                              _fechaCompra = picked;
                              _fechaVencimiento = picked.add(const Duration(days: 30));
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDatePickerTile(
                        label: 'Vencimiento',
                        date: _fechaVencimiento,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaVencimiento,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _fechaVencimiento = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sección 6: Vendedor y Notas
                _buildTextField(
                  controller: _vendedorCtrl,
                  label: 'Vendedor',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _notasCtrl,
                  label: 'Notas Adicionales',
                  icon: Icons.note_alt_outlined,
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.netflixRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: Text(
                      esEdicion ? 'ACTUALIZAR PANTALLA' : 'GUARDAR PANTALLA',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final venta = double.tryParse(_valorVentaCtrl.text) ?? 0.0;
    final compra = double.tryParse(_valorCompraCtrl.text) ?? 0.0;
    final clienteNombre = _clienteCtrl.text.trim().toUpperCase();
    final clienteTelefono = _telefonoCtrl.text.trim();

    final account = StreamingAccountModel(
      id: widget.accountParaEditar?.id ?? 'acc_${DateTime.now().millisecondsSinceEpoch}',
      proveedor: _proveedorCtrl.text.trim().toUpperCase(),
      servicio: _servicioCtrl.text.trim().toUpperCase(),
      cuenta: _cuentaCtrl.text.trim(),
      clave: _claveCtrl.text.trim(),
      perfil: _perfilCtrl.text.trim(),
      pin: _pinCtrl.text.trim(),
      cliente: clienteNombre,
      telefono: clienteTelefono,
      fechaCompra: _fechaCompra,
      fechaVencimiento: _fechaVencimiento,
      vendedor: _vendedorCtrl.text.trim().toUpperCase(),
      estado: _estado,
      valorVenta: venta,
      valorCompra: compra,
      notas: _notasCtrl.text.trim(),
    );

    if (widget.accountParaEditar != null) {
      await widget.controller.updateAccount(account);
    } else {
      await widget.controller.addAccount(account);
    }

    // Si el cliente no existe en el directorio de clientes, guardarlo automáticamente
    if (clienteNombre.isNotEmpty) {
      try {
        final todos = await ClientsService.getAll();
        final existe = todos.any((c) => c.nombre.toUpperCase() == clienteNombre);
        if (!existe) {
          await ClientsService.add(clienteNombre, clienteTelefono);
        }
      } catch (_) {}
    }

    if (mounted) Navigator.pop(context);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.netflixRed)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownOrField({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required IconData icon,
    ValueChanged<String>? onCustomSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (onCustomSelected != null) {
          onCustomSelected(val);
        } else {
          setState(() => controller.text = val);
        }
      },
      itemBuilder: (context) => items
          .map((item) => PopupMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13))))
          .toList(),
      child: _buildTextField(
        controller: controller,
        label: label,
        icon: icon,
      ),
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppTheme.netflixRed),
                const SizedBox(width: 6),
                Text(dateFormat.format(date), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
