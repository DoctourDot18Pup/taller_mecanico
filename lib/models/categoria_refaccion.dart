class CategoriaRefaccion {
  final int? id;
  final String nombre;
  final String? descripcion;

  CategoriaRefaccion({this.id, required this.nombre, this.descripcion});

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
  };

  factory CategoriaRefaccion.fromMap(Map<String, dynamic> map) =>
    CategoriaRefaccion(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
    );
}