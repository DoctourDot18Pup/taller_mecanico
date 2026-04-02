import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/database_helper.dart';
import '../models/orden_servicio.dart';
import 'registro_orden_screen.dart';
import 'editar_orden_screen.dart';
import '../models/cliente.dart';

class OrdenesScreen extends StatefulWidget {
  @override
  _OrdenesScreenState createState() => _OrdenesScreenState();
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
    return Colors.white; // Todos completados
  }

  List<OrdenServicio> get _ordenesFiltradas {
    if (_filtroEstado == 'todos') return _ordenes;
    return _ordenes.where((o) => o.estado == _filtroEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Taller Mecánico - Órdenes'),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _mostrarDialogoFiltros,
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendario
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
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
                  if (ordenesDelDia.isEmpty) return SizedBox.shrink();

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
                            padding: EdgeInsets.only(left: 2),
                            child: Text(
                              '${ordenesDelDia.length}',
                              style: TextStyle(fontSize: 8),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Listado de órdenes con Sliver (Requisito de evaluación)
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
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
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final orden = _ordenesFiltradas[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: orden.getEstadoColor().withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForEstado(orden.estado),
                              color: orden.getEstadoColor(),
                            ),
                          ),
                          title: Text(
                            'Orden #${orden.id}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total: \$${orden.totalGeneral.toStringAsFixed(2)}'),
                              Text(
                                'Entrada: ${_formatearFecha(orden.fechaEntrada)}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              orden.getEstadoTexto(),
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: orden.getEstadoColor(),
                            padding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onTap: () => _editarOrden(orden),
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
        icon: Icon(Icons.add),
        label: Text('Nueva Orden'),
        backgroundColor: Colors.blue[900],
      ),
    );
  }

  IconData _getIconForEstado(String estado) {
    switch(estado) {
      case 'pendiente': return Icons.pending;
      case 'en_progreso': return Icons.build;
      case 'completado': return Icons.check_circle;
      case 'cancelado': return Icons.cancel;
      default: return Icons.car_repair;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  void _mostrarDialogoFiltros() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtrar órdenes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFiltroOpcion('Todos', 'todos'),
            _buildFiltroOpcion('Pendientes', 'pendiente'),
            _buildFiltroOpcion('En Progreso', 'en_progreso'),
            _buildFiltroOpcion('Completados', 'completado'),
            _buildFiltroOpcion('Cancelados', 'cancelado'),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroOpcion(String titulo, String valor) {
    return ListTile(
      title: Text(titulo),
      leading: Radio(
        value: valor,
        groupValue: _filtroEstado,
        onChanged: (value) {
          setState(() => _filtroEstado = value as String);
          Navigator.pop(context);
        },
      ),
    );
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Text(
                  'Órdenes del ${dia.day}/${dia.month}/${dia.year}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: ordenesDelDia.length,
                  itemBuilder: (context, index) {
                    final orden = ordenesDelDia[index];
                    return FutureBuilder<Cliente?>(
                      future: DatabaseHelper().getClienteById(orden.clienteId),
                      builder: (context, snapshot) {
                        final cliente = snapshot.data;
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                            trailing: Icon(Icons.chevron_right),
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