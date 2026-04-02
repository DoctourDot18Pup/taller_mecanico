import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/formateadores.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});
  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  DateTime _mes = DateTime.now();
  Map<String, dynamic>? _stats;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final stats = await DatabaseHelper().getEstadisticasMes(_mes);
    setState(() {
      _stats = stats;
      _cargando = false;
    });
  }

  void _cambiarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta, 1));
    _cargar();
  }

  bool get _esMesActual =>
      _mes.month == DateTime.now().month && _mes.year == DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: Column(
        children: [
          // ── Selector de mes ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _cambiarMes(-1),
                ),
                Text(
                  Fmt.mes(_mes),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _esMesActual ? null : () => _cambiarMes(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (_cargando)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildContenido(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    final s = _stats!;
    final scheme = Theme.of(context).colorScheme;
    final total = s['count'] as int;
    final completadas = s['completadas'] as int;
    final pct = total == 0 ? 0.0 : completadas / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI principal — ingresos
        _KpiCard(
          label: 'Ingresos del mes',
          value: Fmt.moneda(s['total'] as double),
          icon: Icons.payments_outlined,
          color: scheme.primary,
          large: true,
        ),
        const SizedBox(height: 12),

        // KPI — total órdenes
        _KpiCard(
          label: 'Órdenes totales',
          value: '$total',
          icon: Icons.assignment_outlined,
          color: Colors.indigo,
        ),
        const SizedBox(height: 20),

        // Grid de estados
        Text(
          'Desglose por estado',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _EstadoCard(label: 'Pendientes', count: s['pendientes'], color: Colors.orange),
            _EstadoCard(label: 'En Progreso', count: s['en_progreso'], color: Colors.blue),
            _EstadoCard(label: 'Completadas', count: completadas, color: Colors.green),
            _EstadoCard(label: 'Canceladas', count: s['canceladas'], color: Colors.red),
          ],
        ),
        const SizedBox(height: 20),

        // Barra de tasa de completadas
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasa de completadas',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: pct,
                  minHeight: 14,
                  borderRadius: BorderRadius.circular(7),
                  color: Colors.green,
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool large;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: large ? 32 : 26),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: large ? 30 : 24,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _EstadoCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
