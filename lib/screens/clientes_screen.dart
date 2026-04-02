import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';
import 'form_cliente_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});
  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Cliente> _clientes = [];
  List<Cliente> _filtrados = [];
  final _busqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final lista = await DatabaseHelper().getClientes();
    setState(() {
      _clientes = lista;
      _filtrar();
    });
  }

  void _filtrar() {
    final q = _busqueda.text.toLowerCase();
    _filtrados = q.isEmpty
        ? List.from(_clientes)
        : _clientes.where((c) =>
            c.nombre.toLowerCase().contains(q) ||
            c.vehiculoPlaca.toLowerCase().contains(q) ||
            c.telefono.contains(q)).toList();
  }

  Future<void> _eliminar(Cliente c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: Text('Se eliminará a ${c.nombre} y todas sus órdenes asociadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper().deleteCliente(c.id!);
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _busqueda,
              hintText: 'Buscar por nombre, placa o teléfono...',
              leading: const Icon(Icons.search),
              onChanged: (_) => setState(_filtrar),
              backgroundColor: WidgetStatePropertyAll(
                isDark ? const Color(0xFF2A2A3E) : Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _filtrados.isEmpty
          ? const Center(child: Text('No hay clientes registrados'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filtrados.length,
              itemBuilder: (context, i) {
                final c = _filtrados[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        c.nombre.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📱 ${c.telefono}'),
                        Text('🚗 ${c.vehiculoModelo} · ${c.vehiculoPlaca}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FormClienteScreen(cliente: c)),
                          ).then((_) => _cargar()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _eliminar(c),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormClienteScreen()),
        ).then((_) => _cargar()),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }
}
