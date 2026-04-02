class Refaccion {
  final int? id;
  final String nombre;
  final String codigoParte;
  final double precio;
  final int stock;
  final String? marca;
  final int? categoriaId;

  Refaccion({
    this.id,
    required this.nombre,
    required this.codigoParte,
    required this.precio,
    required this.stock,
    this.marca,
    this.categoriaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo_parte': codigoParte,
      'precio': precio,
      'stock': stock,
      'marca': marca,
      'categoria_id': categoriaId,
    };
  }

  factory Refaccion.fromMap(Map<String, dynamic> map) {
    return Refaccion(
      id: map['id'],
      nombre: map['nombre'],
      codigoParte: map['codigo_parte'],
      precio: map['precio'],
      stock: map['stock'],
      marca: map['marca'],
      categoriaId: map['categoria_id'],
    );
  }
  
  bool get tieneStock => stock > 0;
  String get stockTexto => tieneStock ? '$stock disponibles' : 'Sin stock';
}