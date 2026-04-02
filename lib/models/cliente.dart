class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String? email;
  final String? direccion;
  final String vehiculoModelo;
  final String vehiculoPlaca;
  final String? vehiculoAnio;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    this.direccion,
    required this.vehiculoModelo,
    required this.vehiculoPlaca,
    this.vehiculoAnio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'vehiculo_modelo': vehiculoModelo,
      'vehiculo_placa': vehiculoPlaca,
      'vehiculo_anio': vehiculoAnio,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      email: map['email'],
      direccion: map['direccion'],
      vehiculoModelo: map['vehiculo_modelo'],
      vehiculoPlaca: map['vehiculo_placa'],
      vehiculoAnio: map['vehiculo_anio'],
    );
  }
  
  String getInfoVehiculo() {
    return '$vehiculoModelo - Placa: $vehiculoPlaca';
  }
}