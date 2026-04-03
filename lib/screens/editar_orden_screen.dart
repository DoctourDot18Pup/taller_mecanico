import 'package:flutter/material.dart';
import '../models/orden_servicio.dart';
import '../models/cliente.dart';
import '../database/database_helper.dart';
import '../utils/formateadores.dart';

class EditarOrdenScreen extends StatefulWidget {
  final OrdenServicio orden;
  const EditarOrdenScreen({super.key, required this.orden});

  @override
  State<EditarOrdenScreen> createState() => _EditarOrdenScreenState();
}

class _EditarOrdenScreenState extends State<EditarOrdenScreen> {
  late String _estadoSeleccionado;
  final _observacionesController = TextEditingController();

  Cliente? _cliente;
  List<Map<String, dynamic>> _detalles = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.orden.estado;
    _observacionesController.text = widget.orden.observaciones ?? '';
    _cargarDatos();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final cliente = await DatabaseHelper().getClienteById(widget.orden.clienteId);
    final detalles = await DatabaseHelper().getDetallesConNombres(widget.orden.id!);
    setState(() {
      _cliente = cliente;
      _detalles = detalles;
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    final ordenActualizada = OrdenServicio(
      id: widget.orden.id,
      clienteId: widget.orden.clienteId,
      fechaEntrada: widget.orden.fechaEntrada,
      fechaSalidaProgramada: widget.orden.fechaSalidaProgramada,
      estado: _estadoSeleccionado,
      fechaRecordatorio: widget.orden.fechaRecordatorio,
      totalManoObra: widget.orden.totalManoObra,
      totalRefacciones: widget.orden.totalRefacciones,
      totalGeneral: widget.orden.totalGeneral,
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
    );

    // Descontar stock solo al completar la orden
    if (widget.orden.estado != 'completado' && _estadoSeleccionado == 'completado') {
      final detalles = await DatabaseHelper().getDetallesByOrden(widget.orden.id!);
      for (final d in detalles) {
        final refId = d['refaccion_id'];
        final cantidad = d['cantidad_refacciones'];
        if (refId != null && (cantidad as int) > 0) {
          await DatabaseHelper().actualizarStock(refId as int, cantidad);
        }
      }
    }

    await DatabaseHelper().updateOrden(ordenActualizada);
    if (mounted) Navigator.pop(context);
  }

  Color _statusColor(String estado) {
    switch (estado) {
      case 'pendiente':   return const Color(0xFFFF9800);
      case 'en_progreso': return const Color(0xFF2196F3);
      case 'completado':  return const Color(0xFF4CAF50);
      case 'cancelado':   return const Color(0xFFF44336);
      default:            return Colors.grey;
    }
  }

  String _statusText(String estado) {
    switch (estado) {
      case 'pendiente':   return 'Pendiente';
      case 'en_progreso': return 'En Progreso';
      case 'completado':  return 'Completado';
      case 'cancelado':   return 'Cancelado';
      default:            return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(widget.orden.estado);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Orden #${widget.orden.id}'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                _statusText(widget.orden.estado),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Cliente y vehículo ──
                  if (_cliente != null) _buildClienteCard(isDark, colorScheme),
                  const SizedBox(height: 12),

                  // ── Fechas ──
                  _buildFechasCard(isDark, colorScheme),
                  const SizedBox(height: 12),

                  // ── Servicios ──
                  if (_detalles.any((d) => d['servicio_id'] != null)) ...[
                    _buildSectionHeader('Servicios de mano de obra', Icons.build_outlined, colorScheme),
                    const SizedBox(height: 8),
                    ..._detalles
                        .where((d) => d['servicio_id'] != null)
                        .map((d) => _buildServicioRow(d, isDark, colorScheme)),
                    const SizedBox(height: 12),
                  ],

                  // ── Refacciones ──
                  if (_detalles.any((d) => d['refaccion_id'] != null)) ...[
                    _buildSectionHeader('Refacciones', Icons.inventory_2_outlined, colorScheme),
                    const SizedBox(height: 8),
                    ..._detalles
                        .where((d) => d['refaccion_id'] != null)
                        .map((d) => _buildRefaccionRow(d, isDark, colorScheme)),
                    const SizedBox(height: 12),
                  ],

                  // ── Totales ──
                  _buildTotalesCard(isDark, colorScheme),
                  const SizedBox(height: 20),

                  // ── Divisor sección edición ──
                  Row(
                    children: [
                      Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.4))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Actualizar orden',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.4))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Estado ──
                  Text(
                    'Estado',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _estadoSeleccionado,
                    items: [
                      'pendiente',
                      'en_progreso',
                      'completado',
                      'cancelado',
                    ].map((estado) {
                      final color = _statusColor(estado);
                      return DropdownMenuItem(
                        value: estado,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(_statusText(estado)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _estadoSeleccionado = value!),
                  ),
                  const SizedBox(height: 16),

                  // ── Observaciones ──
                  Text(
                    'Observaciones',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _observacionesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Notas adicionales...',
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: FilledButton(
          onPressed: _cargando ? null : _guardar,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Guardar cambios'),
        ),
      ),
    );
  }

  Widget _buildClienteCard(bool isDark, ColorScheme colorScheme) {
    final c = _cliente!;
    return _Card(
      isDark: isDark,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline_rounded, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.nombre,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 4),
                    Text(c.telefono, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.directions_car_outlined, size: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${c.vehiculoModelo}  •  ${c.vehiculoPlaca}',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFechasCard(bool isDark, ColorScheme colorScheme) {
    return _Card(
      isDark: isDark,
      child: Row(
        children: [
          Expanded(
            child: _FechaItem(
              label: 'Entrada',
              icon: Icons.login_rounded,
              fecha: Fmt.fecha(widget.orden.fechaEntrada),
              colorScheme: colorScheme,
              context: context,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _FechaItem(
              label: 'Salida programada',
              icon: Icons.logout_rounded,
              fecha: Fmt.fecha(widget.orden.fechaSalidaProgramada),
              colorScheme: colorScheme,
              context: context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildServicioRow(Map<String, dynamic> d, bool isDark, ColorScheme colorScheme) {
    final nombre = d['servicio_nombre'] as String? ?? '—';
    final horas = d['servicio_horas'] as int? ?? 0;
    final subtotal = (d['subtotal'] as num).toDouble();

    return _ItemRow(
      isDark: isDark,
      icon: Icons.build_outlined,
      iconColor: const Color(0xFF2196F3),
      title: nombre,
      subtitle: '$horas ${horas == 1 ? 'hora' : 'horas'} de trabajo',
      trailing: Fmt.moneda(subtotal),
      trailingColor: const Color(0xFF2196F3),
      context: context,
    );
  }

  Widget _buildRefaccionRow(Map<String, dynamic> d, bool isDark, ColorScheme colorScheme) {
    final nombre = d['refaccion_nombre'] as String? ?? '—';
    final codigo = d['refaccion_codigo'] as String? ?? '';
    final cantidad = d['cantidad_refacciones'] as int? ?? 0;
    final subtotal = (d['subtotal'] as num).toDouble();

    return _ItemRow(
      isDark: isDark,
      icon: Icons.inventory_2_outlined,
      iconColor: const Color(0xFF9C27B0),
      title: nombre,
      subtitle: '$cantidad ${cantidad == 1 ? 'pieza' : 'piezas'}  •  $codigo',
      trailing: Fmt.moneda(subtotal),
      trailingColor: const Color(0xFF9C27B0),
      context: context,
    );
  }

  Widget _buildTotalesCard(bool isDark, ColorScheme colorScheme) {
    final o = widget.orden;
    return _Card(
      isDark: isDark,
      child: Column(
        children: [
          _TotalRow(
            label: 'Mano de obra',
            value: Fmt.moneda(o.totalManoObra),
            context: context,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          _TotalRow(
            label: 'Refacciones',
            value: Fmt.moneda(o.totalRefacciones),
            context: context,
            colorScheme: colorScheme,
          ),
          Divider(height: 20, color: colorScheme.outline.withValues(alpha: 0.4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total general',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                Fmt.moneda(o.totalGeneral),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers de layout ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2535) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE8ECF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FechaItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String fecha;
  final ColorScheme colorScheme;
  final BuildContext context;

  const _FechaItem({
    required this.label,
    required this.icon,
    required this.fecha,
    required this.colorScheme,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: colorScheme.onSurface.withValues(alpha: 0.45)),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fecha,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final BuildContext context;

  const _ItemRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252D3D) : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE8ECF0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              color: trailingColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;
  final ColorScheme colorScheme;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.context,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext ctx) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
