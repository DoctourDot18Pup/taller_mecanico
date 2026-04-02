import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/servicio_mano_obra.dart';
import '../models/categoria_servicio.dart';

class FormServicioScreen extends StatefulWidget {
  final ServicioManoObra? servicio;
  const FormServicioScreen({super.key, this.servicio});
  @override
  State<FormServicioScreen> createState() => _FormServicioScreenState();
}

class _FormServicioScreenState extends State<FormServicioScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre, _descripcion, _precio, _duracion;
  List<CategoriaServicio> _categorias = [];
  CategoriaServicio? _categoriaSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final s = widget.servicio;
    _nombre = TextEditingController(text: s?.nombre ?? '');
    _descripcion = TextEditingController(text: s?.descripcion ?? '');
    _precio = TextEditingController(text: s != null ? s.precioEstimado.toString() : '');
    _duracion = TextEditingController(text: s != null ? s.duracionHoras.toString() : '1');
    _cargarCategorias();
  }

  @override
  void dispose() {
    for (var c in [_nombre, _descripcion, _precio, _duracion]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    final cats = await DatabaseHelper().getCategoriasServicio();
    setState(() {
      _categorias = cats;
      if (widget.servicio != null) {
        _categoriaSeleccionada =
            cats.where((c) => c.id == widget.servicio!.categoriaId).firstOrNull;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final servicio = ServicioManoObra(
      id: widget.servicio?.id,
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      precioEstimado: double.parse(_precio.text),
      duracionHoras: int.parse(_duracion.text),
      categoriaId: _categoriaSeleccionada?.id,
    );
    if (widget.servicio == null) {
      await DatabaseHelper().insertServicio(servicio);
    } else {
      await DatabaseHelper().updateServicio(servicio);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.servicio != null;
    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Servicio' : 'Nuevo Servicio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
                filled: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcion,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                filled: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precio,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio estimado *',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _duracion,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duración (horas) *',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final n = int.tryParse(v);
                      if (n == null || n < 1) return 'Mínimo 1';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoriaServicio>(
              initialValue: _categoriaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                filled: true,
              ),
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.nombre)))
                  .toList(),
              onChanged: (c) => setState(() => _categoriaSeleccionada = c),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          label: Text(esEdicion ? 'Guardar cambios' : 'Crear servicio'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
