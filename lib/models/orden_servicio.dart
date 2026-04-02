import 'package:flutter/material.dart';

class OrdenServicio {
  final int? id;
  final int clienteId;
  final DateTime fechaEntrada;
  final DateTime fechaSalidaProgramada;
  final String estado; // 'pendiente', 'en_progreso', 'completado', 'cancelado'
  final DateTime? fechaRecordatorio;
  final double totalManoObra;
  final double totalRefacciones;
  final double totalGeneral;
  final String? observaciones;

  OrdenServicio({
    this.id,
    required this.clienteId,
    required this.fechaEntrada,
    required this.fechaSalidaProgramada,
    required this.estado,
    this.fechaRecordatorio,
    this.totalManoObra = 0,
    this.totalRefacciones = 0,
    this.totalGeneral = 0,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'fecha_entrada': fechaEntrada.toIso8601String(),
      'fecha_salida_programada': fechaSalidaProgramada.toIso8601String(),
      'estado': estado,
      'fecha_recordatorio': fechaRecordatorio?.toIso8601String(),
      'total_mano_obra': totalManoObra,
      'total_refacciones': totalRefacciones,
      'total_general': totalGeneral,
      'observaciones': observaciones,
    };
  }

  factory OrdenServicio.fromMap(Map<String, dynamic> map) {
    return OrdenServicio(
      id: map['id'],
      clienteId: map['cliente_id'],
      fechaEntrada: DateTime.parse(map['fecha_entrada']),
      fechaSalidaProgramada: DateTime.parse(map['fecha_salida_programada']),
      estado: map['estado'],
      fechaRecordatorio: map['fecha_recordatorio'] != null 
          ? DateTime.parse(map['fecha_recordatorio']) 
          : null,
      totalManoObra: map['total_mano_obra'],
      totalRefacciones: map['total_refacciones'],
      totalGeneral: map['total_general'],
      observaciones: map['observaciones'],
    );
  }
  
  // Helper para saber el color según estado
  Color getEstadoColor() {
    switch(estado) {
      case 'pendiente': return Colors.orange;
      case 'en_progreso': return Colors.blue;
      case 'completado': return Colors.green;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  String getEstadoTexto() {
    switch(estado) {
      case 'pendiente': return 'Pendiente';
      case 'en_progreso': return 'En Progreso';
      case 'completado': return 'Completado';
      case 'cancelado': return 'Cancelado';
      default: return estado;
    }
  }
}