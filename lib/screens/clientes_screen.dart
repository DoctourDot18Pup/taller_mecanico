import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';
import '../main.dart';
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
  bool _searchVisible = false;

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
        : _clientes
            .where((c) =>
                c.nombre.toLowerCase().contains(q) ||
                c.vehiculoPlaca.toLowerCase().contains(q) ||
                c.telefono.contains(q))
            .toList();
  }

  Future<void> _eliminar(Cliente c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: Text(
          'Se eliminará a ${c.nombre} y todas sus órdenes asociadas.',
        ),
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
    if (ok == true) {
      await DatabaseHelper().deleteCliente(c.id!);
      _cargar();
    }
  }

  Color _avatarColor(String nombre) {
    final colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFF26A69A),
      const Color(0xFF42A5F5),
      const Color(0xFFAB47BC),
      const Color(0xFFEF5350),
      const Color(0xFFFF7043),
      const Color(0xFF66BB6A),
      const Color(0xFF26C6DA),
    ];
    return colors[nombre.codeUnitAt(0) % colors.length];
  }

  Widget _buildClienteCard(Cliente c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final avatarColor = _avatarColor(c.nombre);
    final initials = c.nombre.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar con iniciales
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.nombre,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.telefono,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
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

            // Acciones
            Column(
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  color: colorScheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormClienteScreen(cliente: c),
                    ),
                  ).then((_) => _cargar()),
                ),
                const SizedBox(height: 6),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red,
                  onTap: () => _eliminar(c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSearch = _busqueda.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
                size: 40,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch ? 'Sin resultados' : 'Sin clientes registrados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Intenta con otro término de búsqueda'
                  : 'Toca el botón + para agregar tu primer cliente',
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _busqueda,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Nombre, placa o teléfono...',
                  hintStyle: TextStyle(
                    color: (isDark ? const Color(0xFFE2E8F0) : Colors.white)
                        .withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(_filtrar),
              )
            : const Text('Clientes'),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _busqueda.clear();
                  _filtrar();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => TallerApp.of(context).toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Contador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Text(
                  'Clientes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filtrados.length}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _filtrados.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: _filtrados.length,
                    itemBuilder: (context, i) => _buildClienteCard(_filtrados[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormClienteScreen()),
        ).then((_) => _cargar()),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
