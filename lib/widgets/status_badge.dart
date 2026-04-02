import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String estado;
  const StatusBadge({super.key, required this.estado});

  Color get _color {
    switch (estado) {
      case 'pendiente': return Colors.orange;
      case 'en_progreso': return Colors.blue;
      case 'completado': return Colors.green;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  String get _texto {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'en_progreso': return 'En Progreso';
      case 'completado': return 'Completado';
      case 'cancelado': return 'Cancelado';
      default: return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color),
      ),
      child: Text(_texto, style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}