import 'package:flutter/material.dart';
import '../models/orden_servicio.dart';
import '../models/servicio_mano_obra.dart';
import '../models/refaccion.dart';
import '../database/database_helper.dart';
import '../utils/formateadores.dart';

class DetalleOrdenScreen extends StatelessWidget {
  final OrdenServicio orden;
  final List<ServicioManoObra> servicios;
  final List<Map<String, dynamic>> refacciones; // {refaccion, cantidad}

  const DetalleOrdenScreen({
    super.key,
    required this.orden,
    required this.servicios,
    required this.refacciones,
  });

  double get _totalServicios =>
      servicios.fold(0, (sum, s) => sum + s.precioEstimado);

  double get _totalRefacciones => refacciones.fold(
      0, (sum, r) => sum + (r['refaccion'] as Refaccion).precio * (r['cantidad'] as int));

  double get _totalGeneral => _totalServicios + _totalRefacciones;

  Future<void> _guardarOrden(BuildContext context) async {
    final db = DatabaseHelper();

    final ordenFinal = OrdenServicio(
      clienteId: orden.clienteId,
      fechaEntrada: orden.fechaEntrada,
      fechaSalidaProgramada: orden.fechaSalidaProgramada,
      estado: orden.estado,
      fechaRecordatorio: orden.fechaRecordatorio,
      totalManoObra: _totalServicios,
      totalRefacciones: _totalRefacciones,
      totalGeneral: _totalGeneral,
      observaciones: orden.observaciones,
    );

    final ordenId = await db.insertOrden(ordenFinal);

    for (final servicio in servicios) {
      await db.insertDetalle({
        'orden_id': ordenId,
        'servicio_id': servicio.id,
        'refaccion_id': null,
        'cantidad_refacciones': 0,
        'precio_servicio_aplicado': servicio.precioEstimado,
        'subtotal': servicio.precioEstimado,
        'notas_tecnicas': null,
      });
    }

    for (final item in refacciones) {
      final ref = item['refaccion'] as Refaccion;
      final cantidad = item['cantidad'] as int;
      await db.insertDetalle({
        'orden_id': ordenId,
        'servicio_id': null,
        'refaccion_id': ref.id,
        'cantidad_refacciones': cantidad,
        'precio_servicio_aplicado': null,
        'subtotal': ref.precio * cantidad,
        'notas_tecnicas': null,
      });
      // Stock is decremented when the order is marked 'completado', not at creation
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Orden registrada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Orden'),
      ),
      body: CustomScrollView(
        slivers: [
          // Servicios
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Servicios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final servicio = servicios[index];
                return ListTile(
                  leading: Icon(Icons.build_outlined, color: colorScheme.primary),
                  title: Text(servicio.nombre),
                  trailing: Text(
                    Fmt.moneda(servicio.precioEstimado),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
              childCount: servicios.length,
            ),
          ),

          // Refacciones
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Refacciones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = refacciones[index];
                final ref = item['refaccion'] as Refaccion;
                final cantidad = item['cantidad'] as int;
                return ListTile(
                  leading: Icon(Icons.inventory_2_outlined, color: colorScheme.secondary),
                  title: Text(ref.nombre),
                  subtitle: Text('Cantidad: $cantidad'),
                  trailing: Text(
                    Fmt.moneda(ref.precio * cantidad),
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
              childCount: refacciones.length,
            ),
          ),

          // Totales
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2535) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE8ECF0),
                ),
              ),
              child: Column(
                children: [
                  _filaTotales(context, 'Mano de obra', _totalServicios),
                  const SizedBox(height: 8),
                  _filaTotales(context, 'Refacciones', _totalRefacciones),
                  Divider(
                    height: 20,
                    color: colorScheme.outline.withValues(alpha: 0.4),
                  ),
                  _filaTotales(context, 'Total general', _totalGeneral, bold: true),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: FilledButton.icon(
          onPressed: () => _guardarOrden(context),
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Confirmar y guardar orden'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _filaTotales(BuildContext context, String label, double valor, {bool bold = false}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(Fmt.moneda(valor), style: style),
      ],
    );
  }
}
