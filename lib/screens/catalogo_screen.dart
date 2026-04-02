import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/servicio_mano_obra.dart';
import '../models/refaccion.dart';
import '../utils/formateadores.dart';
import 'form_servicio_screen.dart';
import 'form_refaccion_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<ServicioManoObra> _servicios = [];
  List<Refaccion> _refacciones = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _cargar();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final s = await DatabaseHelper().getServicios();
    final r = await DatabaseHelper().getRefacciones();
    setState(() {
      _servicios = s;
      _refacciones = r;
    });
  }

  Future<bool?> _confirmarEliminacion(String nombre) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¿Eliminar?'),
          content: Text('Se eliminará "$nombre" del catálogo.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

  Future<void> _eliminarServicio(ServicioManoObra s) async {
    final ok = await _confirmarEliminacion(s.nombre);
    if (ok == true) {
      await DatabaseHelper().deleteServicio(s.id!);
      _cargar();
    }
  }

  Future<void> _eliminarRefaccion(Refaccion r) async {
    final ok = await _confirmarEliminacion(r.nombre);
    if (ok == true) {
      await DatabaseHelper().deleteRefaccion(r.id!);
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.build), text: 'Servicios'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Refacciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildServicios(),
          _buildRefacciones(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tab.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FormServicioScreen()),
            ).then((_) => _cargar());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FormRefaccionScreen()),
            ).then((_) => _cargar());
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tab.index == 0 ? 'Nuevo Servicio' : 'Nueva Refacción'),
      ),
    );
  }

  Widget _buildServicios() {
    if (_servicios.isEmpty) {
      return const Center(child: Text('No hay servicios registrados'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: _servicios.length,
      itemBuilder: (_, i) {
        final s = _servicios[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.15),
              child: const Icon(Icons.build, color: Colors.blue),
            ),
            title: Text(s.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${Fmt.moneda(s.precioEstimado)} · ${s.getDuracionTexto()}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FormServicioScreen(servicio: s)),
                  ).then((_) => _cargar()),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _eliminarServicio(s),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRefacciones() {
    if (_refacciones.isEmpty) {
      return const Center(child: Text('No hay refacciones registradas'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: _refacciones.length,
      itemBuilder: (_, i) {
        final r = _refacciones[i];
        final stockColor = r.stock == 0
            ? Colors.red
            : r.stock < 5
                ? Colors.orange
                : Colors.green;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: stockColor.withValues(alpha: 0.15),
              child: Icon(Icons.inventory_2, color: stockColor),
            ),
            title: Text(r.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${Fmt.moneda(r.precio)} · ${r.codigoParte}'
              '${r.marca != null ? ' · ${r.marca}' : ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(
                    '${r.stock}',
                    style: TextStyle(
                        color: stockColor, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: stockColor.withValues(alpha: 0.1),
                  side: BorderSide(color: stockColor),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FormRefaccionScreen(refaccion: r)),
                  ).then((_) => _cargar()),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _eliminarRefaccion(r),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
