import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/refaccion.dart';
import '../models/categoria_refaccion.dart';

class FormRefaccionScreen extends StatefulWidget {
  final Refaccion? refaccion;
  const FormRefaccionScreen({super.key, this.refaccion});
  @override
  State<FormRefaccionScreen> createState() => _FormRefaccionScreenState();
}

class _FormRefaccionScreenState extends State<FormRefaccionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre, _codigo, _precio, _stock, _marca;
  List<CategoriaRefaccion> _categorias = [];
  CategoriaRefaccion? _categoriaSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final r = widget.refaccion;
    _nombre = TextEditingController(text: r?.nombre ?? '');
    _codigo = TextEditingController(text: r?.codigoParte ?? '');
    _precio = TextEditingController(text: r != null ? r.precio.toString() : '');
    _stock = TextEditingController(text: r != null ? r.stock.toString() : '0');
    _marca = TextEditingController(text: r?.marca ?? '');
    _cargarCategorias();
  }

  @override
  void dispose() {
    for (var c in [_nombre, _codigo, _precio, _stock, _marca]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    final cats = await DatabaseHelper().getCategoriasRefaccion();
    setState(() {
      _categorias = cats;
      if (widget.refaccion != null) {
        _categoriaSeleccionada =
            cats.where((c) => c.id == widget.refaccion!.categoriaId).firstOrNull;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final refaccion = Refaccion(
      id: widget.refaccion?.id,
      nombre: _nombre.text.trim(),
      codigoParte: _codigo.text.trim().toUpperCase(),
      precio: double.parse(_precio.text),
      stock: int.parse(_stock.text),
      marca: _marca.text.trim().isEmpty ? null : _marca.text.trim(),
      categoriaId: _categoriaSeleccionada?.id,
    );
    try {
      if (widget.refaccion == null) {
        await DatabaseHelper().insertRefaccion(refaccion);
      } else {
        await DatabaseHelper().updateRefaccion(refaccion);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: el código de parte ya existe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.refaccion != null;
    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Refacción' : 'Nueva Refacción')),
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
              controller: _codigo,
              decoration: const InputDecoration(
                labelText: 'Código de parte *',
                border: OutlineInputBorder(),
                filled: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precio,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio *',
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
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock *',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final n = int.tryParse(v);
                      if (n == null || n < 0) return 'Mínimo 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _marca,
              decoration: const InputDecoration(
                labelText: 'Marca',
                hintText: 'opcional',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoriaRefaccion>(
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
          label: Text(esEdicion ? 'Guardar cambios' : 'Registrar refacción'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
