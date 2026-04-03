import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/formateadores.dart';
import '../main.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => TallerApp.of(context).toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Selector de mes ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                _NavButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _cambiarMes(-1),
                ),
                Expanded(
                  child: Text(
                    Fmt.mes(_mes),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                _NavButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: _esMesActual ? null : () => _cambiarMes(1),
                ),
              ],
            ),
          ),

          if (_cargando)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: _buildContenido(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    final s = _stats!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = s['count'] as int;
    final completadas = s['completadas'] as int;
    final pendientes = s['pendientes'] as int;
    final enProgreso = s['en_progreso'] as int;
    final canceladas = s['canceladas'] as int;
    final pct = total == 0 ? 0.0 : completadas / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── KPI principal — ingresos ──
        _buildHeroKpi(
          label: 'Ingresos del mes',
          value: Fmt.moneda(s['total'] as double),
          icon: Icons.account_balance_wallet_outlined,
          color: colorScheme.primary,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // ── KPI órdenes totales ──
        _buildHeroKpi(
          label: 'Órdenes registradas',
          value: '$total',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF7C3AED),
          isDark: isDark,
          subtitle: total == 1 ? '1 orden este mes' : '$total órdenes este mes',
        ),
        const SizedBox(height: 24),

        // ── Encabezado desglose ──
        Row(
          children: [
            Text(
              'Desglose por estado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Barras de progreso por estado ──
        _buildStatusRow(
          label: 'Pendientes',
          count: pendientes,
          total: total,
          color: const Color(0xFFFF9800),
          icon: Icons.pending_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStatusRow(
          label: 'En Progreso',
          count: enProgreso,
          total: total,
          color: const Color(0xFF2196F3),
          icon: Icons.build_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStatusRow(
          label: 'Completadas',
          count: completadas,
          total: total,
          color: const Color(0xFF4CAF50),
          icon: Icons.check_circle_outline_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStatusRow(
          label: 'Canceladas',
          count: canceladas,
          total: total,
          color: const Color(0xFFF44336),
          icon: Icons.cancel_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // ── Tasa de completadas ──
        _buildCompletionCard(pct: pct, isDark: isDark),
      ],
    );
  }

  Widget _buildHeroKpi({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2535) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE8ECF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    final pct = total == 0 ? 0.0 : count / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2535) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE8ECF0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard({required double pct, required bool isDark}) {
    const color = Color(0xFF4CAF50);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2535) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3245) : const Color(0xFFE8ECF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tasa de completadas',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct == 0
                ? 'Sin órdenes completadas este mes'
                : pct == 1.0
                    ? '¡Todas las órdenes completadas!'
                    : '${(pct * 100).toStringAsFixed(0)}% de las órdenes finalizadas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.25),
          size: 20,
        ),
      ),
    );
  }
}
