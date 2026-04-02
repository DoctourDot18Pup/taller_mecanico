import 'package:flutter/material.dart';
import '../models/orden_servicio.dart';
import '../models/servicio_mano_obra.dart';
import '../models/refaccion.dart';
import '../database/database_helper.dart';

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
      0, (sum, r) => sum + (r['refaccion'] as Refaccion).precio * r['cantidad']);

  double get _totalGeneral => _totalServicios + _totalRefacciones;

  Future<void> _guardarOrden(BuildContext context) async {
    final db = DatabaseHelper();

    // Guardar orden con totales
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

    // Guardar detalles de servicios
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

    // Guardar detalles de refacciones y actualizar stock
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
      await db.actualizarStock(ref.id!, cantidad);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Orden registrada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      // Regresar hasta OrdenesScreen
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Orden'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          // Servicios
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Servicios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final servicio = servicios[index];
                return ListTile(
                  leading: const Icon(Icons.build, color: Colors.blue),
                  title: Text(servicio.nombre),
                  trailing: Text('\$${servicio.precioEstimado.toStringAsFixed(2)}'),
                );
              },
              childCount: servicios.length,
            ),
          ),

          // Refacciones
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Refacciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = refacciones[index];
                final ref = item['refaccion'] as Refaccion;
                final cantidad = item['cantidad'] as int;
                return ListTile(
                  leading: const Icon(Icons.settings, color: Colors.orange),
                  title: Text(ref.nombre),
                  subtitle: Text('Cantidad: $cantidad'),
                  trailing: Text('\$${(ref.precio * cantidad).toStringAsFixed(2)}'),
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  _filaTotales('Mano de obra', _totalServicios),
                  _filaTotales('Refacciones', _totalRefacciones),
                  const Divider(),
                  _filaTotales('Total general', _totalGeneral, bold: true),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _guardarOrden(context),
          icon: const Icon(Icons.check_circle),
          label: const Text('Confirmar y guardar orden'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _filaTotales(String label, double valor, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('\$${valor.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}