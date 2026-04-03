import 'package:flutter/material.dart';
import '../models/orden_servicio.dart';
import '../database/database_helper.dart';

class EditarOrdenScreen extends StatefulWidget {
  final OrdenServicio orden;
  const EditarOrdenScreen({super.key, required this.orden});

  @override
  State<EditarOrdenScreen> createState() => _EditarOrdenScreenState();
}

class _EditarOrdenScreenState extends State<EditarOrdenScreen> {
  late String _estadoSeleccionado;
  final _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.orden.estado;
    _observacionesController.text = widget.orden.observaciones ?? '';
  }

  Future<void> _guardar() async {
    final ordenActualizada = OrdenServicio(
      id: widget.orden.id,
      clienteId: widget.orden.clienteId,
      fechaEntrada: widget.orden.fechaEntrada,
      fechaSalidaProgramada: widget.orden.fechaSalidaProgramada,
      estado: _estadoSeleccionado,
      fechaRecordatorio: widget.orden.fechaRecordatorio,
      totalManoObra: widget.orden.totalManoObra,
      totalRefacciones: widget.orden.totalRefacciones,
      totalGeneral: widget.orden.totalGeneral,
      observaciones: _observacionesController.text,
    );

    // Decrement stock only when transitioning to 'completado'
    if (widget.orden.estado != 'completado' && _estadoSeleccionado == 'completado') {
      final detalles = await DatabaseHelper().getDetallesByOrden(widget.orden.id!);
      for (final d in detalles) {
        final refId = d['refaccion_id'];
        final cantidad = d['cantidad_refacciones'];
        if (refId != null && (cantidad as int) > 0) {
          await DatabaseHelper().actualizarStock(refId as int, cantidad);
        }
      }
    }

    await DatabaseHelper().updateOrden(ordenActualizada);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Orden #${widget.orden.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _estadoSeleccionado,
              items: const [
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'en_progreso', child: Text('En Progreso')),
                DropdownMenuItem(value: 'completado', child: Text('Completado')),
                DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
              ],
              onChanged: (value) => setState(() => _estadoSeleccionado = value!),
            ),
            const SizedBox(height: 16),
            Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _observacionesController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Notas adicionales...',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _guardar,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}