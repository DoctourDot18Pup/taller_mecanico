import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../models/cliente.dart';
import '../models/orden_servicio.dart';
import '../models/servicio_mano_obra.dart';
import '../models/refaccion.dart';
import '../models/categoria_servicio.dart';
import '../models/categoria_refaccion.dart';
import 'detalle_orden_screen.dart';
import '../utils/formateadores.dart';

class RegistroOrdenScreen extends StatefulWidget {
  @override
  _RegistroOrdenScreenState createState() => _RegistroOrdenScreenState();
}

class _RegistroOrdenScreenState extends State<RegistroOrdenScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Datos de la orden
  Cliente? _clienteSeleccionado;
  DateTime _fechaEntrada = DateTime.now();
  DateTime _fechaSalida = DateTime.now().add(Duration(days: 2));
  DateTime? _fechaRecordatorio;
  String _observaciones = '';
  
  // Carrito de la orden (servicios y refacciones)
  List<Map<String, dynamic>> _carrito = [];
  
  // Control de tabs
  int _tabIndex = 0;
  
  // Categorías y items
  List<CategoriaServicio> _categoriasServicio = [];
  List<CategoriaRefaccion> _categoriasRefaccion = [];
  List<ServicioManoObra> _servicios = [];
  List<Refaccion> _refacciones = [];
  
  CategoriaServicio? _categoriaServicioSeleccionada;
  CategoriaRefaccion? _categoriaRefaccionSeleccionada;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _tabIndex = _tabController.index);
        }
      });
    _cargarCategorias();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    final categoriasServicio = await DatabaseHelper().getCategoriasServicio();
    final categoriasRefaccion = await DatabaseHelper().getCategoriasRefaccion();
    setState(() {
      _categoriasServicio = categoriasServicio;
      _categoriasRefaccion = categoriasRefaccion;
    });
  }

  Future<void> _cargarServiciosPorCategoria(int categoriaId) async {
    final servicios = await DatabaseHelper().getServiciosPorCategoria(categoriaId);
    setState(() => _servicios = servicios);
  }

  Future<void> _cargarRefaccionesPorCategoria(int categoriaId) async {
    final refacciones = await DatabaseHelper().getRefaccionesPorCategoria(categoriaId);
    setState(() => _refacciones = refacciones);
  }

  void _agregarServicio(ServicioManoObra servicio) {
    setState(() {
      final existingIndex = _carrito.indexWhere(
        (item) => item['tipo'] == 'servicio' && (item['item'] as ServicioManoObra).id == servicio.id,
      );
      if (existingIndex >= 0) {
        final current = _carrito[existingIndex];
        final newCantidad = (current['cantidad'] as int) + 1;
        _carrito[existingIndex] = {
          ...current,
          'cantidad': newCantidad,
          'subtotal': servicio.precioEstimado * newCantidad,
        };
      } else {
        _carrito.add({
          'tipo': 'servicio',
          'item': servicio,
          'precio': servicio.precioEstimado,
          'cantidad': 1,
          'subtotal': servicio.precioEstimado,
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Servicio "${servicio.nombre}" agregado')),
    );
  }

  void _agregarRefaccion(Refaccion refaccion) {
    if (!refaccion.tieneStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin stock disponible'), backgroundColor: Colors.red),
      );
      return;
    }

    final existingIndex = _carrito.indexWhere(
      (item) => item['tipo'] == 'refaccion' && (item['item'] as Refaccion).id == refaccion.id,
    );
    final cantidadExistente = existingIndex >= 0 ? (_carrito[existingIndex]['cantidad'] as int) : 0;

    int cantidad = cantidadExistente > 0 ? cantidadExistente : 1;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${existingIndex >= 0 ? 'Actualizar' : 'Agregar'} ${refaccion.nombre}'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Precio unitario: \$${refaccion.precio}'),
                const SizedBox(height: 10),
                Text('Stock disponible: ${refaccion.stock}'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (cantidad > 1) setStateDialog(() => cantidad--);
                      },
                    ),
                    Text('$cantidad', style: const TextStyle(fontSize: 20)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (cantidad < refaccion.stock) setStateDialog(() => cantidad++);
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (existingIndex >= 0) {
                  final current = _carrito[existingIndex];
                  _carrito[existingIndex] = {
                    ...current,
                    'cantidad': cantidad,
                    'subtotal': refaccion.precio * cantidad,
                  };
                } else {
                  _carrito.add({
                    'tipo': 'refaccion',
                    'item': refaccion,
                    'precio': refaccion.precio,
                    'cantidad': cantidad,
                    'subtotal': refaccion.precio * cantidad,
                  });
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${refaccion.nombre} actualizado en el carrito')),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  double get _totalManoObra {
    return _carrito
        .where((item) => item['tipo'] == 'servicio')
        .fold(0, (sum, item) => sum + (item['subtotal'] as double));
  }

  double get _totalRefacciones {
    return _carrito
        .where((item) => item['tipo'] == 'refaccion')
        .fold(0, (sum, item) => sum + (item['subtotal'] as double));
  }

  double get _totalGeneral => _totalManoObra + _totalRefacciones;

  Future<void> _guardarOrden() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona un cliente'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agrega al menos un servicio o refacción'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final orden = OrdenServicio(
      clienteId: _clienteSeleccionado!.id!,
      fechaEntrada: _fechaEntrada,
      fechaSalidaProgramada: _fechaSalida,
      estado: 'pendiente',
      fechaRecordatorio: _fechaRecordatorio,
      totalManoObra: _totalManoObra,
      totalRefacciones: _totalRefacciones,
      totalGeneral: _totalGeneral,
      observaciones: _observaciones.isEmpty ? null : _observaciones,
    );
    
    int ordenId = await DatabaseHelper().insertOrden(orden);
    
    // Guardar detalles
    for (var item in _carrito) {
      await DatabaseHelper().insertDetalle({
        'orden_id': ordenId,
        'servicio_id': item['tipo'] == 'servicio' ? (item['item'] as ServicioManoObra).id : null,
        'refaccion_id': item['tipo'] == 'refaccion' ? (item['item'] as Refaccion).id : null,
        'cantidad_refacciones': item['cantidad'] ?? 0,
        'precio_servicio_aplicado': item['tipo'] == 'servicio' ? item['precio'] : null,
        'subtotal': item['subtotal'],
        'notas_tecnicas': null,
      });
      
    }
    
    // Programar notificación
    if (_fechaRecordatorio != null) {
      await NotificationService().scheduleNotification(
        ordenId,
        'Recordatorio de servicio',
        'El vehículo de ${_clienteSeleccionado!.nombre} tiene servicio pendiente',
        _fechaRecordatorio!,
      );
    }
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Orden #$ordenId registrada con éxito'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Orden de Servicio'),
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 0, end: 3),
            badgeContent: Text('${_carrito.length}'),
            child: IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () => _mostrarCarrito(),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Selección de cliente
            Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  title: Text(_clienteSeleccionado?.nombre ?? 'Seleccionar cliente'),
                  subtitle: _clienteSeleccionado != null 
                      ? Text(_clienteSeleccionado!.getInfoVehiculo())
                      : null,
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => _seleccionarCliente(),
                ),
              ),
            ),
            
            // Fechas
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFechaPicker('Fecha entrada', _fechaEntrada, (date) {
                      setState(() => _fechaEntrada = date);
                    }),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildFechaPicker('Fecha salida', _fechaSalida, (date) {
                      setState(() => _fechaSalida = date);
                    }),
                  ),
                ],
              ),
            ),
            
            // Recordatorio
            CheckboxListTile(
              title: Text('Programar recordatorio 2 días antes'),
              subtitle: Text('Se enviará una notificación de recordatorio'),
              value: _fechaRecordatorio != null,
              onChanged: (value) {
                if (value == true) {
                  setState(() => _fechaRecordatorio = _fechaEntrada.subtract(Duration(days: 2)));
                } else {
                  setState(() => _fechaRecordatorio = null);
                }
              },
            ),
            
            // Tabs para Servicios y Refacciones
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Servicios', icon: Icon(Icons.build)),
                Tab(text: 'Refacciones', icon: Icon(Icons.shopping_cart)),
              ],
            ),
            
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _buildServiciosTab(),
                  _buildRefaccionesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: FilledButton(
            onPressed: _guardarOrden,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('TERMINAR REGISTRO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildServiciosTab() {
    return Column(
      children: [
        // Categorías de servicios
        Padding(
          padding: EdgeInsets.all(16),
          child: DropdownButtonFormField<CategoriaServicio>(
            decoration: InputDecoration(labelText: 'Categoría de servicio'),
            items: _categoriasServicio.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat.nombre));
            }).toList(),
            onChanged: (categoria) {
              setState(() => _categoriaServicioSeleccionada = categoria);
              _cargarServiciosPorCategoria(categoria!.id!);
            },
          ),
        ),
        
        // Lista de servicios
        Expanded(
          child: _servicios.isEmpty
              ? Center(child: Text('Selecciona una categoría'))
              : ListView.builder(
                  itemCount: _servicios.length,
                  itemBuilder: (context, index) {
                    final servicio = _servicios[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.build, color: Theme.of(context).colorScheme.primary),
                        title: Text(servicio.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(servicio.descripcion ?? ''),
                            Text('\$${servicio.precioEstimado} - ${servicio.getDuracionTexto()}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.add, color: Colors.green),
                          onPressed: () => _agregarServicio(servicio),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRefaccionesTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: DropdownButtonFormField<CategoriaRefaccion>(
            decoration: InputDecoration(labelText: 'Categoría de refacción'),
            items: _categoriasRefaccion.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat.nombre));
            }).toList(),
            onChanged: (categoria) {
              setState(() => _categoriaRefaccionSeleccionada = categoria);
              _cargarRefaccionesPorCategoria(categoria!.id!);
            },
          ),
        ),
        
        Expanded(
          child: _refacciones.isEmpty
              ? Center(child: Text('Selecciona una categoría'))
              : ListView.builder(
                  itemCount: _refacciones.length,
                  itemBuilder: (context, index) {
                    final refaccion = _refacciones[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.shopping_cart, 
                            color: refaccion.tieneStock ? Colors.green : Colors.red),
                        title: Text(refaccion.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Código: ${refaccion.codigoParte}'),
                            Text('\$${refaccion.precio} - ${refaccion.stockTexto}'),
                            if (refaccion.marca != null) Text('Marca: ${refaccion.marca}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.add, color: refaccion.tieneStock ? Colors.green : Colors.grey),
                          onPressed: refaccion.tieneStock ? () => _agregarRefaccion(refaccion) : null,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFechaPicker(String label, DateTime fecha, Function(DateTime) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: fecha,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 365)),
            );
            if (date != null) onChanged(date);
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${fecha.day}/${fecha.month}/${fecha.year}'),
                Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _seleccionarCliente() async {
    final clientes = await DatabaseHelper().getClientes();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Seleccionar cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: clientes.length,
                itemBuilder: (context, index) {
                  final cliente = clientes[index];
                  return ListTile(
                    leading: Icon(Icons.person),
                    title: Text(cliente.nombre),
                    subtitle: Text(cliente.getInfoVehiculo()),
                    onTap: () {
                      setState(() => _clienteSeleccionado = cliente);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCarrito() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: 500,
        child: Column(
          children: [
            Text('Carrito de Servicios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _carrito.length,
                itemBuilder: (context, index) {
                  final item = _carrito[index];
                  final esServicio = item['tipo'] == 'servicio';
                  final nombre = esServicio 
                      ? (item['item'] as ServicioManoObra).nombre 
                      : (item['item'] as Refaccion).nombre;
                  
                  return ListTile(
                    leading: Icon(esServicio ? Icons.build : Icons.shopping_cart),
                    title: Text(nombre),
                    subtitle: Text('${item['cantidad']}x — ${Fmt.moneda(item['subtotal'] as double)}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _carrito.removeAt(index));
                        Navigator.pop(context);
                        _mostrarCarrito();
                      },
                    ),
                  );
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Total Mano Obra:', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('\$${_totalManoObra.toStringAsFixed(2)}'),
            ),
            ListTile(
              title: Text('Total Refacciones:', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('\$${_totalRefacciones.toStringAsFixed(2)}'),
            ),
            ListTile(
              title: Text('TOTAL GENERAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              trailing: Text('\$${_totalGeneral.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}