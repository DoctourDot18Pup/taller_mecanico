class ServicioManoObra {
  final int? id;
  final String nombre;
  final String? descripcion;
  final double precioEstimado;
  final int duracionHoras;
  final int? categoriaId;

  ServicioManoObra({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precioEstimado,
    required this.duracionHoras,
    this.categoriaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_estimado': precioEstimado,
      'duracion_horas': duracionHoras,
      'categoria_id': categoriaId,
    };
  }

  factory ServicioManoObra.fromMap(Map<String, dynamic> map) {
    return ServicioManoObra(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precioEstimado: map['precio_estimado'],
      duracionHoras: map['duracion_horas'],
      categoriaId: map['categoria_id'],
    );
  }
  
  String getDuracionTexto() {
    if (duracionHoras == 1) return '1 hora';
    return '$duracionHoras horas';
  }
}