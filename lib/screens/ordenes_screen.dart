import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/database_helper.dart';
import '../models/orden_servicio.dart';
import '../models/cliente.dart';
import '../utils/formateadores.dart';
import '../main.dart';
import 'registro_orden_screen.dart';
import 'editar_orden_screen.dart';
import '../widgets/filtro_header.dart';

class OrdenesScreen extends StatefulWidget {
  const OrdenesScreen({super.key});
  @override
  State<OrdenesScreen> createState() => _OrdenesScreenState();
}

class _OrdenesScreenState extends State<OrdenesScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<OrdenServicio>> _eventos = {};
  String _filtroEstado = 'todos';
  List<OrdenServicio> _ordenes = [];
  Map<int, Cliente> _clientesMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final ordenes = await DatabaseHelper().getOrdenes();
    final clientes = await DatabaseHelper().getClientes();
    final map = <int, Cliente>{};
    for (final c in clientes) {
      if (c.id != null) map[c.id!] = c;
    }
    setState(() {
      _ordenes = ordenes;
      _clientesMap = map;
    });
    await _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    final eventosTemp = await DatabaseHelper().getOrdenesAgrupadasPorFecha();
    setState(() {
      _eventos = eventosTemp;
    });
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'pendiente': return const Color(0xFFFF9800);
      case 'en_progreso': return const Color(0xFF2196F3);
      case 'completado': return const Color(0xFF4CAF50);
      case 'cancelado': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }

  Color _getPuntoColor(List<OrdenServicio> ordenesDelDia) {
    if (ordenesDelDia.any((o) => o.estado == 'pendiente')) return const Color(0xFFFF9800);
    if (ordenesDelDia.any((o) => o.estado == 'en_progreso')) return const Color(0xFF2196F3);
    if (ordenesDelDia.any((o) => o.estado == 'cancelado')) return const Color(0xFFF44336);
    return const Color(0xFF4CAF50);
  }

  List<OrdenServicio> get _ordenesFiltradas {
    if (_filtroEstado == 'todos') return _ordenes;
    return _ordenes.where((o) => o.estado == _filtroEstado).toList();
  }

  Future<bool?> _confirmarCancelacion(OrdenServicio orden) async {
    if (orden.estado == 'completado' || orden.estado == 'cancelado') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No puedes cancelar una orden ${orden.estado == 'completado' ? 'completada' : 'ya cancelada'}',
          ),
        ),
      );
      return false;
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar orden?'),
        content: Text(
          '¿Deseas cancelar la Orden #${orden.id}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarOrden(OrdenServicio orden) async {
    setState(() {
      _ordenes.removeWhere((o) => o.id == orden.id);
    });

    final ordenCancelada = OrdenServicio(
      id: orden.id,
      clienteId: orden.clienteId,
      fechaEntrada: orden.fechaEntrada,
      fechaSalidaProgramada: orden.fechaSalidaProgramada,
      estado: 'cancelado',
      fechaRecordatorio: orden.fechaRecordatorio,
      totalManoObra: orden.totalManoObra,
      totalRefacciones: orden.totalRefacciones,
      totalGeneral: orden.totalGeneral,
      observaciones: orden.observaciones,
    );
    await DatabaseHelper().updateOrden(ordenCancelada);
    await _cargarDatos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Orden #${orden.id} cancelada'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Widget _buildOrdenCard(OrdenServicio orden) {
    final cliente = _clientesMap[orden.clienteId];
    final statusColor = _getStatusColor(orden.estado);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2535) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE8ECF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja de color de estado
              Container(width: 4, color: statusColor),

              // Contenido principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado: número de orden + chip de estado
                      Row(
                        children: [
                          Text(
                            'Orden #${orden.id}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          _buildStatusChip(orden.estado, statusColor),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Cliente y vehículo
                      if (cliente != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                cliente.nombre,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${cliente.vehiculoModelo}  •  ${cliente.vehiculoPlaca}',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Divisor
                      Divider(
                        height: 1,
                        color: colorScheme.outline.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 10),

                      // Fechas y total
                      Row(
                        children: [
                          _buildInfoPill(
                            icon: Icons.login_rounded,
                            label: Fmt.fecha(orden.fechaEntrada),
                            color: colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoPill(
                            icon: Icons.logout_rounded,
                            label: Fmt.fecha(orden.fechaSalidaProgramada),
                            color: colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                          const Spacer(),
                          Text(
                            Fmt.moneda(orden.totalGeneral),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String estado, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getEstadoTexto(estado),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.car_repair_rounded,
                size: 40,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _filtroEstado == 'todos'
                  ? 'Sin órdenes registradas'
                  : 'Sin órdenes ${_getEstadoTexto(_filtroEstado).toLowerCase()}s',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para crear una nueva orden de servicio',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'en_progreso': return 'En Progreso';
      case 'completado': return 'Completado';
      case 'cancelado': return 'Cancelado';
      default: return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => TallerApp.of(context).toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendario
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final surfaceColor = Theme.of(context).colorScheme.surface;
            final onSurface = Theme.of(context).colorScheme.onSurface;
            final primary = Theme.of(context).colorScheme.primary;

            return Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              decoration: BoxDecoration(
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2027, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _mostrarModalEventos(selectedDay);
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                headerStyle: HeaderStyle(
                  titleTextStyle: TextStyle(
                    color: onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left_rounded, color: onSurface),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded, color: onSurface),
                  formatButtonTextStyle: TextStyle(color: onSurface, fontSize: 12),
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: onSurface.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: primary.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: TextStyle(color: onSurface),
                  weekendTextStyle: TextStyle(color: primary),
                  outsideTextStyle: TextStyle(color: onSurface.withValues(alpha: 0.3)),
                  disabledTextStyle: TextStyle(color: onSurface.withValues(alpha: 0.2)),
                  todayDecoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  markersMaxCount: 0,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final clave = DateTime(day.year, day.month, day.day);
                    final ordenesDelDia = _eventos[clave] ?? [];
                    if (ordenesDelDia.isEmpty) return const SizedBox.shrink();

                    final puntos = ordenesDelDia.take(4).map((o) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getPuntoColor([o]),
                          border: Border.all(color: surfaceColor, width: 0.5),
                        ),
                      );
                    }).toList();

                    return Positioned(
                      bottom: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: puntos,
                      ),
                    );
                  },
                ),
              ),
            );
          }),

          // Lista con filtros y tarjetas
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Filtros pegajosos
                SliverPersistentHeader(
                  pinned: true,
                  delegate: FiltroHeaderDelegate(
                    filtroActual: _filtroEstado,
                    onFiltroChanged: (valor) {
                      setState(() => _filtroEstado = valor);
                    },
                  ),
                ),

                // Encabezado con conteo
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Row(
                      children: [
                        Text(
                          'Órdenes de Servicio',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_ordenesFiltradas.length}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista o estado vacío
                if (_ordenesFiltradas.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final orden = _ordenesFiltradas[index];
                        return Dismissible(
                          key: Key('orden_${orden.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmarCancelacion(orden),
                          onDismissed: (_) => _cancelarOrden(orden),
                          background: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_outlined, color: Colors.white, size: 26),
                                SizedBox(height: 4),
                                Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => _editarOrden(orden),
                            child: _buildOrdenCard(orden),
                          ),
                        );
                      },
                      childCount: _ordenesFiltradas.length,
                    ),
                  ),

                // Padding inferior para el FAB
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevaOrden(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Orden'),
      ),
    );
  }

  void _mostrarModalEventos(DateTime dia) {
    final clave = DateTime(dia.year, dia.month, dia.day);
    final ordenesDelDia = _eventos[clave] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) {
          final colorScheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${dia.day}/${dia.month}/${dia.year}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${ordenesDelDia.length} ${ordenesDelDia.length == 1 ? 'orden' : 'órdenes'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.3)),

                // Lista
                Expanded(
                  child: ordenesDelDia.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 48,
                                color: colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sin órdenes este día',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: ordenesDelDia.length,
                          itemBuilder: (context, index) {
                            final orden = ordenesDelDia[index];
                            final cliente = _clientesMap[orden.clienteId];
                            final statusColor = _getStatusColor(orden.estado);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF252D3D) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2A3245)
                                      : const Color(0xFFE8ECF0),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Container(width: 4, color: statusColor),
                                      Expanded(
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          leading: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.receipt_long_rounded,
                                              color: statusColor,
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            'Orden #${orden.id}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (cliente != null)
                                                Text(
                                                  cliente.nombre,
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              Text(
                                                Fmt.moneda(orden.totalGeneral),
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: _buildStatusChip(orden.estado, statusColor),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _editarOrden(orden);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _nuevaOrden() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegistroOrdenScreen()),
    ).then((_) => _cargarDatos());
  }

  void _editarOrden(OrdenServicio orden) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditarOrdenScreen(orden: orden)),
    ).then((_) => _cargarDatos());
  }
}
