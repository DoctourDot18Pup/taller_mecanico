import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cliente.dart';
import '../models/orden_servicio.dart';
import '../models/servicio_mano_obra.dart';
import '../models/refaccion.dart';
import '../models/categoria_servicio.dart';
import '../models/categoria_refaccion.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'taller_mecanico.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ==================== TABLA CLIENTES ====================
    await db.execute('''
      CREATE TABLE clientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        email TEXT,
        direccion TEXT,
        vehiculo_modelo TEXT NOT NULL,
        vehiculo_placa TEXT NOT NULL UNIQUE,
        vehiculo_anio TEXT
      )
    ''');

    // ==================== TABLA CATEGORÍAS DE SERVICIOS ====================
    await db.execute('''
      CREATE TABLE categorias_servicio(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT
      )
    ''');

    // ==================== TABLA SERVICIOS DE MANO DE OBRA ====================
    await db.execute('''
      CREATE TABLE servicios_mano_obra(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precio_estimado REAL NOT NULL,
        duracion_horas INTEGER NOT NULL,
        categoria_id INTEGER,
        FOREIGN KEY(categoria_id) REFERENCES categorias_servicio(id) ON DELETE SET NULL
      )
    ''');

    // ==================== TABLA CATEGORÍAS DE REFACCIONES ====================
    await db.execute('''
      CREATE TABLE categorias_refaccion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT
      )
    ''');

    // ==================== TABLA REFACCIONES ====================
    await db.execute('''
      CREATE TABLE refacciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        codigo_parte TEXT NOT NULL UNIQUE,
        precio REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        marca TEXT,
        categoria_id INTEGER,
        FOREIGN KEY(categoria_id) REFERENCES categorias_refaccion(id) ON DELETE SET NULL
      )
    ''');

    // ==================== TABLA ÓRDENES DE SERVICIO ====================
    await db.execute('''
      CREATE TABLE ordenes_servicio(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        fecha_entrada TEXT NOT NULL,
        fecha_salida_programada TEXT NOT NULL,
        estado TEXT NOT NULL CHECK(estado IN ('pendiente', 'en_progreso', 'completado', 'cancelado')),
        fecha_recordatorio TEXT,
        total_mano_obra REAL NOT NULL DEFAULT 0,
        total_refacciones REAL NOT NULL DEFAULT 0,
        total_general REAL NOT NULL DEFAULT 0,
        observaciones TEXT,
        FOREIGN KEY(cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
      )
    ''');

    // ==================== TABLA DETALLES DE ORDEN ====================
    await db.execute('''
      CREATE TABLE detalles_orden(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orden_id INTEGER NOT NULL,
        servicio_id INTEGER,
        refaccion_id INTEGER,
        cantidad_refacciones INTEGER DEFAULT 0,
        precio_servicio_aplicado REAL,
        subtotal REAL NOT NULL,
        notas_tecnicas TEXT,
        FOREIGN KEY(orden_id) REFERENCES ordenes_servicio(id) ON DELETE CASCADE,
        FOREIGN KEY(servicio_id) REFERENCES servicios_mano_obra(id),
        FOREIGN KEY(refaccion_id) REFERENCES refacciones(id),
        CHECK(servicio_id IS NOT NULL OR refaccion_id IS NOT NULL)
      )
    ''');

    // ==================== DATOS DE EJEMPLO ====================
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Categorías de servicios
    await db.insert('categorias_servicio', {
      'nombre': 'Motor',
      'descripcion': 'Servicios relacionados con el motor del vehículo'
    });
    await db.insert('categorias_servicio', {
      'nombre': 'Frenos',
      'descripcion': 'Sistema de frenado'
    });
    await db.insert('categorias_servicio', {
      'nombre': 'Suspensión',
      'descripcion': 'Sistema de suspensión y dirección'
    });
    await db.insert('categorias_servicio', {
      'nombre': 'Eléctrico',
      'descripcion': 'Sistema eléctrico y electrónico'
    });

    // Servicios de mano de obra
    await db.insert('servicios_mano_obra', {
      'nombre': 'Afinación mayor',
      'descripcion': 'Cambio de bujías, filtros, aceite y calibración',
      'precio_estimado': 1500,
      'duracion_horas': 3,
      'categoria_id': 1
    });
    await db.insert('servicios_mano_obra', {
      'nombre': 'Cambio de pastillas de freno',
      'descripcion': 'Reemplazo de pastillas delanteras o traseras',
      'precio_estimado': 800,
      'duracion_horas': 2,
      'categoria_id': 2
    });
    await db.insert('servicios_mano_obra', {
      'nombre': 'Alineación y balanceo',
      'descripcion': 'Alineación de dirección y balanceo de llantas',
      'precio_estimado': 600,
      'duracion_horas': 1,
      'categoria_id': 3
    });
    await db.insert('servicios_mano_obra', {
      'nombre': 'Diagnóstico eléctrico',
      'descripcion': 'Escaneo y diagnóstico de fallas eléctricas',
      'precio_estimado': 500,
      'duracion_horas': 1,
      'categoria_id': 4
    });

    // Categorías de refacciones
    await db.insert('categorias_refaccion', {
      'nombre': 'Filtros',
      'descripcion': 'Filtros de aceite, aire, gasolina'
    });
    await db.insert('categorias_refaccion', {
      'nombre': 'Lubricantes',
      'descripcion': 'Aceites y lubricantes'
    });
    await db.insert('categorias_refaccion', {
      'nombre': 'Frenos',
      'descripcion': 'Pastillas, discos, líquido de frenos'
    });
    await db.insert('categorias_refaccion', {
      'nombre': 'Eléctricos',
      'descripcion': 'Baterías, fusibles, sensores'
    });

    // Refacciones
    await db.insert('refacciones', {
      'nombre': 'Filtro de aceite',
      'codigo_parte': 'FO-001',
      'precio': 120,
      'stock': 50,
      'marca': 'Bosch',
      'categoria_id': 1
    });
    await db.insert('refacciones', {
      'nombre': 'Aceite 5W30 (1L)',
      'codigo_parte': 'AC-5W30',
      'precio': 180,
      'stock': 30,
      'marca': 'Mobil',
      'categoria_id': 2
    });
    await db.insert('refacciones', {
      'nombre': 'Pastillas de freno delanteras',
      'codigo_parte': 'PF-001',
      'precio': 450,
      'stock': 20,
      'marca': 'Brembo',
      'categoria_id': 3
    });
    await db.insert('refacciones', {
      'nombre': 'Batería 12V',
      'codigo_parte': 'BAT-12V',
      'precio': 1800,
      'stock': 10,
      'marca': 'LTH',
      'categoria_id': 4
    });

    // Cliente de ejemplo
    await db.insert('clientes', {
      'nombre': 'Juan Pérez',
      'telefono': '555-1234',
      'email': 'juan@example.com',
      'direccion': 'Av. Principal 123',
      'vehiculo_modelo': 'Toyota Corolla 2020',
      'vehiculo_placa': 'ABC-1234',
      'vehiculo_anio': '2020'
    });
  }

  // ==================== CRUD CLIENTES ====================
  Future<int> insertCliente(Cliente cliente) async {
    Database db = await database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> getClientes() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clientes');
    return List.generate(maps.length, (i) => Cliente.fromMap(maps[i]));
  }

  Future<Cliente?> getClienteById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Cliente.fromMap(maps.first);
    return null;
  }

  // ==================== CRUD ÓRDENES DE SERVICIO ====================
  Future<int> insertOrden(OrdenServicio orden) async {
    Database db = await database;
    return await db.insert('ordenes_servicio', orden.toMap());
  }

  Future<List<OrdenServicio>> getOrdenes() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('ordenes_servicio');
    return List.generate(maps.length, (i) => OrdenServicio.fromMap(maps[i]));
  }

  Future<List<OrdenServicio>> getOrdenesPorEstado(String estado) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ordenes_servicio',
      where: 'estado = ?',
      whereArgs: [estado],
    );
    return List.generate(maps.length, (i) => OrdenServicio.fromMap(maps[i]));
  }

  Future<int> updateOrden(OrdenServicio orden) async {
    Database db = await database;
    return await db.update(
      'ordenes_servicio',
      orden.toMap(),
      where: 'id = ?',
      whereArgs: [orden.id],
    );
  }

  Future<int> deleteOrden(int id) async {
    Database db = await database;
    return await db.delete('ordenes_servicio', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD SERVICIOS MANO OBRA ====================
  Future<List<ServicioManoObra>> getServicios() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('servicios_mano_obra');
    return List.generate(maps.length, (i) => ServicioManoObra.fromMap(maps[i]));
  }

  Future<List<ServicioManoObra>> getServiciosPorCategoria(int categoriaId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'servicios_mano_obra',
      where: 'categoria_id = ?',
      whereArgs: [categoriaId],
    );
    return List.generate(maps.length, (i) => ServicioManoObra.fromMap(maps[i]));
  }

  // ==================== CRUD REFACCIONES ====================
  Future<List<Refaccion>> getRefacciones() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('refacciones');
    return List.generate(maps.length, (i) => Refaccion.fromMap(maps[i]));
  }

  Future<List<Refaccion>> getRefaccionesPorCategoria(int categoriaId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'refacciones',
      where: 'categoria_id = ?',
      whereArgs: [categoriaId],
    );
    return List.generate(maps.length, (i) => Refaccion.fromMap(maps[i]));
  }

  Future<bool> actualizarStock(int refaccionId, int cantidadVendida) async {
    Database db = await database;
    Refaccion? refaccion = await getRefaccionById(refaccionId);
    if (refaccion == null) return false;
    
    int nuevoStock = refaccion.stock - cantidadVendida;
    if (nuevoStock < 0) return false;
    
    int result = await db.update(
      'refacciones',
      {'stock': nuevoStock},
      where: 'id = ?',
      whereArgs: [refaccionId],
    );
    return result > 0;
  }

  Future<Refaccion?> getRefaccionById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'refacciones',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Refaccion.fromMap(maps.first);
    return null;
  }

  // ==================== CRUD DETALLES ====================
  Future<int> insertDetalle(Map<String, dynamic> detalle) async {
    Database db = await database;
    return await db.insert('detalles_orden', detalle);
  }

  Future<List<Map<String, dynamic>>> getDetallesByOrden(int ordenId) async {
    Database db = await database;
    return await db.query(
      'detalles_orden',
      where: 'orden_id = ?',
      whereArgs: [ordenId],
    );
  }

  /// Returns detail rows enriched with service/refacción names via LEFT JOIN.
  Future<List<Map<String, dynamic>>> getDetallesConNombres(int ordenId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT
        d.id, d.servicio_id, d.refaccion_id,
        d.cantidad_refacciones, d.precio_servicio_aplicado,
        d.subtotal, d.notas_tecnicas,
        s.nombre  AS servicio_nombre,
        s.duracion_horas AS servicio_horas,
        r.nombre  AS refaccion_nombre,
        r.codigo_parte AS refaccion_codigo
      FROM detalles_orden d
      LEFT JOIN servicios_mano_obra s ON d.servicio_id  = s.id
      LEFT JOIN refacciones         r ON d.refaccion_id = r.id
      WHERE d.orden_id = ?
    ''', [ordenId]);
  }

  // ==================== CATEGORÍAS ====================
  Future<List<CategoriaServicio>> getCategoriasServicio() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categorias_servicio');
    return List.generate(maps.length, (i) => CategoriaServicio.fromMap(maps[i]));
  }

  Future<List<CategoriaRefaccion>> getCategoriasRefaccion() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categorias_refaccion');
    return List.generate(maps.length, (i) => CategoriaRefaccion.fromMap(maps[i]));
  }

  // ==================== REPORTES Y CONSULTAS ESPECIALES ====================
  
  /// Obtiene órdenes agrupadas por fecha para el calendario
  Future<Map<DateTime, List<OrdenServicio>>> getOrdenesAgrupadasPorFecha() async {
    final ordenes = await getOrdenes();
    Map<DateTime, List<OrdenServicio>> agrupadas = {};
    
    for (var orden in ordenes) {
      final fecha = DateTime(orden.fechaEntrada.year, orden.fechaEntrada.month, orden.fechaEntrada.day);
      if (!agrupadas.containsKey(fecha)) {
        agrupadas[fecha] = [];
      }
      agrupadas[fecha]!.add(orden);
    }
    return agrupadas;
  }

  /// Obtiene órdenes que requieren recordatorio (fecha_recordatorio <= hoy + 2 días)
  Future<List<OrdenServicio>> getOrdenesConRecordatorioPendiente() async {
    Database db = await database;
    final hoy = DateTime.now();
    final limite = hoy.add(Duration(days: 2));

    final List<Map<String, dynamic>> maps = await db.query(
      'ordenes_servicio',
      where: 'fecha_recordatorio IS NOT NULL AND fecha_recordatorio <= ? AND estado IN (?, ?)',
      whereArgs: [limite.toIso8601String(), 'pendiente', 'en_progreso'],
    );
    return List.generate(maps.length, (i) => OrdenServicio.fromMap(maps[i]));
  }

  // ==================== CRUD CLIENTES COMPLETO ====================
  Future<int> updateCliente(Cliente cliente) async {
    Database db = await database;
    return await db.update('clientes', cliente.toMap(), where: 'id = ?', whereArgs: [cliente.id]);
  }

  Future<int> deleteCliente(int id) async {
    Database db = await database;
    return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD SERVICIOS COMPLETO ====================
  Future<int> insertServicio(ServicioManoObra servicio) async {
    Database db = await database;
    return await db.insert('servicios_mano_obra', servicio.toMap());
  }

  Future<int> updateServicio(ServicioManoObra servicio) async {
    Database db = await database;
    return await db.update('servicios_mano_obra', servicio.toMap(), where: 'id = ?', whereArgs: [servicio.id]);
  }

  Future<int> deleteServicio(int id) async {
    Database db = await database;
    return await db.delete('servicios_mano_obra', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD REFACCIONES COMPLETO ====================
  Future<int> insertRefaccion(Refaccion refaccion) async {
    Database db = await database;
    return await db.insert('refacciones', refaccion.toMap());
  }

  Future<int> updateRefaccion(Refaccion refaccion) async {
    Database db = await database;
    return await db.update('refacciones', refaccion.toMap(), where: 'id = ?', whereArgs: [refaccion.id]);
  }

  Future<int> deleteRefaccion(int id) async {
    Database db = await database;
    return await db.delete('refacciones', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CATEGORÍAS INSERT ====================
  Future<int> insertCategoriaServicio(CategoriaServicio cat) async {
    Database db = await database;
    return await db.insert('categorias_servicio', cat.toMap());
  }

  Future<int> insertCategoriaRefaccion(CategoriaRefaccion cat) async {
    Database db = await database;
    return await db.insert('categorias_refaccion', cat.toMap());
  }

  // ==================== ESTADÍSTICAS DEL MES ====================
  Future<Map<String, dynamic>> getEstadisticasMes(DateTime mes) async {
    Database db = await database;
    final inicio = DateTime(mes.year, mes.month, 1).toIso8601String();
    final fin = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59).toIso8601String();

    final ordenes = await db.query(
      'ordenes_servicio',
      where: 'fecha_entrada >= ? AND fecha_entrada <= ?',
      whereArgs: [inicio, fin],
    );

    double totalMes = 0;
    int pendientes = 0, enProgreso = 0, completadas = 0, canceladas = 0;
    for (var o in ordenes) {
      totalMes += (o['total_general'] as num).toDouble();
      switch (o['estado']) {
        case 'pendiente': pendientes++; break;
        case 'en_progreso': enProgreso++; break;
        case 'completado': completadas++; break;
        case 'cancelado': canceladas++; break;
      }
    }

    return {
      'total': totalMes,
      'count': ordenes.length,
      'pendientes': pendientes,
      'en_progreso': enProgreso,
      'completadas': completadas,
      'canceladas': canceladas,
    };
  }
}