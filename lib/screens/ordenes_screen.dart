import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/database_helper.dart';
import '../models/orden_servicio.dart';
import '../utils/formateadores.dart';
import '../main.dart';
import 'registro_orden_screen.dart';
import 'editar_orden_screen.dart';
import '../models/cliente.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final ordenes = await DatabaseHelper().getOrdenes();
    setState(() {
      _ordenes = ordenes;
    });
    await _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    final eventosTemp = await DatabaseHelper().getOrdenesAgrupadasPorFecha();
    setState(() {
      _eventos = eventosTemp;
    });
  }

  Color _getPuntoColor(List<OrdenServicio> ordenesDelDia) {
    if (ordenesDelDia.any((o) => o.estado == 'pendiente')) return Colors.green;
    if (ordenesDelDia.any((o) => o.estado == 'en_progreso')) return Colors.blue;
    if (ordenesDelDia.any((o) => o.estado == 'cancelado')) return Colors.red;
    return Colors.white;
  }

  List<OrdenServicio> get _ordenesFiltradas {
    if (_filtroEstado == 'todos') return _ordenes;
    return _ordenes.where((o) => o.estado == _filtroEstado).toList();
  }

  Future<bool?> _confirmarCancelacion(OrdenServicio orden) async {
    if (orden.estado == 'completado' || orden.estado == 'cancelado') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No puedes cancelar una orden ${orden.estado == 'completado' ? 'completada' : 'ya cancelada'}')),
      );
      return false;
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar orden?'),
        content: Text('¿Deseas cancelar la Orden #${orden.id}? Esta acción no se puede deshacer.'),
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
    // Remove immediately so the dismissed key never reappears mid-frame
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
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
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
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => TallerApp.of(context).toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendario
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2026, 12, 31),
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
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue[900],
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final ordenesDelDia = _eventos[day] ?? [];
                  if (ordenesDelDia.isEmpty) return const SizedBox.shrink();

                  return Positioned(
                    bottom: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getPuntoColor(ordenesDelDia),
                          ),
                        ),
                        if (ordenesDelDia.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Text(
                              '${ordenesDelDia.length}',
                              style: const TextStyle(fontSize: 8),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Listado con SliverPersistentHeader y Dismissible
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Filtros persistentes
                SliverPersistentHeader(
                  pinned: true,
                  delegate: FiltroHeaderDelegate(
                    filtroActual: _filtroEstado,
                    onFiltroChanged: (valor) {
                      setState(() => _filtroEstado = valor);
                    },
                  ),
                ),

                // Contador de registros
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Órdenes de Servicio',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_ordenesFiltradas.length} registros',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista con Dismissible
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
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, color: Colors.white, size: 28),
                              SizedBox(height: 4),
                              Text(
                                'Cancelar',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          elevation: 2,
                          child: ListTile(
                            leading: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: orden.getEstadoColor().withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForEstado(orden.estado),
                                color: orden.getEstadoColor(),
                              ),
                            ),
                            title: Text(
                              'Orden #${orden.id}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total: \$${orden.totalGeneral.toStringAsFixed(2)}'),
                                Text(
                                  'Entrada: ${Fmt.fecha(orden.fechaEntrada)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                orden.getEstadoTexto(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor: orden.getEstadoColor(),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onTap: () => _editarOrden(orden),
                          ),
                        ),
                      );
                    },
                    childCount: _ordenesFiltradas.length,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevaOrden(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Orden'),
        backgroundColor: Colors.blue[900],
      ),
    );
  }

  IconData _getIconForEstado(String estado) {
    switch (estado) {
      case 'pendiente': return Icons.pending;
      case 'en_progreso': return Icons.build;
      case 'completado': return Icons.check_circle;
      case 'cancelado': return Icons.cancel;
      default: return Icons.car_repair;
    }
  }

  void _mostrarModalEventos(DateTime dia) {
    final ordenesDelDia = _eventos[dia] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Text(
                  'Órdenes del ${dia.day}/${dia.month}/${dia.year}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Expanded(
                child: ordenesDelDia.isEmpty
                    ? const Center(child: Text('No hay órdenes para este día'))
                    : ListView.builder(
                        controller: controller,
                        itemCount: ordenesDelDia.length,
                        itemBuilder: (context, index) {
                          final orden = ordenesDelDia[index];
                          return FutureBuilder<Cliente?>(
                            future: DatabaseHelper().getClienteById(orden.clienteId),
                            builder: (context, snapshot) {
                              final cliente = snapshot.data;
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: Icon(Icons.car_repair, color: orden.getEstadoColor()),
                                  title: Text('Orden #${orden.id}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (cliente != null) Text(cliente.nombre),
                                      Text('Total: \$${orden.totalGeneral}'),
                                      Text('Estado: ${orden.getEstadoTexto()}'),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _editarOrden(orden);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
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