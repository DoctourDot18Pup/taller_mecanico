class CategoriaServicio {
  final int? id;
  final String nombre;
  final String? descripcion;

  CategoriaServicio({this.id, required this.nombre, this.descripcion});

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
  };

  factory CategoriaServicio.fromMap(Map<String, dynamic> map) =>
    CategoriaServicio(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
    );
}