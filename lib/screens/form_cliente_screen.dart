import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';

class FormClienteScreen extends StatefulWidget {
  final Cliente? cliente;
  const FormClienteScreen({super.key, this.cliente});
  @override
  State<FormClienteScreen> createState() => _FormClienteScreenState();
}

class _FormClienteScreenState extends State<FormClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre, _telefono, _email, _direccion,
      _modelo, _placa, _anio;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombre    = TextEditingController(text: c?.nombre ?? '');
    _telefono  = TextEditingController(text: c?.telefono ?? '');
    _email     = TextEditingController(text: c?.email ?? '');
    _direccion = TextEditingController(text: c?.direccion ?? '');
    _modelo    = TextEditingController(text: c?.vehiculoModelo ?? '');
    _placa     = TextEditingController(text: c?.vehiculoPlaca ?? '');
    _anio      = TextEditingController(text: c?.vehiculoAnio ?? '');
  }

  @override
  void dispose() {
    for (var c in [_nombre, _telefono, _email, _direccion, _modelo, _placa, _anio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final cliente = Cliente(
      id: widget.cliente?.id,
      nombre: _nombre.text.trim(),
      telefono: _telefono.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      direccion: _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
      vehiculoModelo: _modelo.text.trim(),
      vehiculoPlaca: _placa.text.trim().toUpperCase(),
      vehiculoAnio: _anio.text.trim().isEmpty ? null : _anio.text.trim(),
    );
    try {
      if (widget.cliente == null) {
        await DatabaseHelper().insertCliente(cliente);
      } else {
        await DatabaseHelper().updateCliente(cliente);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: placa ya registrada o datos inválidos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: true,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.cliente != null;
    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Cliente' : 'Nuevo Cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Datos personales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _field('Nombre completo', _nombre, required: true),
            _field('Teléfono', _telefono, required: true, keyboard: TextInputType.phone),
            _field('Email', _email, hint: 'opcional', keyboard: TextInputType.emailAddress),
            _field('Dirección', _direccion, hint: 'opcional'),
            const Divider(height: 24),
            Text(
              'Datos del vehículo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _field('Modelo del vehículo', _modelo, required: true, hint: 'ej. Toyota Corolla'),
            _field('Placa', _placa, required: true, hint: 'ej. ABC-1234'),
            _field('Año', _anio, hint: 'opcional', keyboard: TextInputType.number),
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
          label: Text(esEdicion ? 'Guardar cambios' : 'Registrar cliente'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
    );
  }
}
