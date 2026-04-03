import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/servicio_mano_obra.dart';
import '../models/refaccion.dart';
import '../utils/formateadores.dart';
import '../main.dart';
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

  Color _stockColor(int stock) {
    if (stock == 0) return const Color(0xFFF44336);
    if (stock < 5) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => TallerApp.of(context).toggleTheme(),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.build_outlined), text: 'Servicios'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Refacciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildServicios(isDark, colorScheme),
          _buildRefacciones(isDark, colorScheme),
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
        icon: const Icon(Icons.add_rounded),
        label: Text(_tab.index == 0 ? 'Nuevo Servicio' : 'Nueva Refacción'),
      ),
    );
  }

  Widget _buildEmptyState({required String mensaje, required IconData icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: colorScheme.primary.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicios(bool isDark, ColorScheme colorScheme) {
    if (_servicios.isEmpty) {
      return _buildEmptyState(
        mensaje: 'Sin servicios registrados',
        icon: Icons.build_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: _servicios.length,
      itemBuilder: (_, i) {
        final s = _servicios[i];
        const color = Color(0xFF2196F3);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2535) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE8ECF0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 6,
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
                  Container(width: 4, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.build_outlined, color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  s.nombre,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      Fmt.moneda(s.precioEstimado),
                                      style: const TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '  •  ${s.getDuracionTexto()}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                if (s.descripcion != null && s.descripcion!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      s.descripcion!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SmallActionButton(
                                icon: Icons.edit_outlined,
                                color: colorScheme.primary,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FormServicioScreen(servicio: s),
                                  ),
                                ).then((_) => _cargar()),
                              ),
                              const SizedBox(height: 6),
                              _SmallActionButton(
                                icon: Icons.delete_outline_rounded,
                                color: Colors.red,
                                onTap: () => _eliminarServicio(s),
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
      },
    );
  }

  Widget _buildRefacciones(bool isDark, ColorScheme colorScheme) {
    if (_refacciones.isEmpty) {
      return _buildEmptyState(
        mensaje: 'Sin refacciones registradas',
        icon: Icons.inventory_2_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: _refacciones.length,
      itemBuilder: (_, i) {
        final r = _refacciones[i];
        final stockColor = _stockColor(r.stock);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2535) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE8ECF0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 6,
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
                  Container(width: 4, color: stockColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: stockColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: stockColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  r.nombre,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      Fmt.moneda(r.precio),
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (r.marca != null && r.marca!.isNotEmpty)
                                      Text(
                                        '  •  ${r.marca}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: stockColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: stockColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        '${r.stock} en stock',
                                        style: TextStyle(
                                          color: stockColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      r.codigoParte,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SmallActionButton(
                                icon: Icons.edit_outlined,
                                color: colorScheme.primary,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FormRefaccionScreen(refaccion: r),
                                  ),
                                ).then((_) => _cargar()),
                              ),
                              const SizedBox(height: 6),
                              _SmallActionButton(
                                icon: Icons.delete_outline_rounded,
                                color: Colors.red,
                                onTap: () => _eliminarRefaccion(r),
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
      },
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
