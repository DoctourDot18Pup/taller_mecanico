import 'package:flutter/material.dart';
import '../models/cliente.dart';

class VehiculoCard extends StatelessWidget {
  final Cliente cliente;
  const VehiculoCard({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car, color: Colors.blue),
        title: Text(cliente.vehiculoModelo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placa: ${cliente.vehiculoPlaca}'),
            if (cliente.vehiculoAnio != null) Text('Año: ${cliente.vehiculoAnio}'),
          ],
        ),
      ),
    );
  }
}