import 'package:flutter/material.dart';

class FiltroHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String filtroActual;
  final Function(String) onFiltroChanged;

  FiltroHeaderDelegate({
    required this.filtroActual,
    required this.onFiltroChanged,
  });

  static const _filtros = [
    {'valor': 'todos', 'label': 'Todos', 'color': Colors.grey},
    {'valor': 'pendiente', 'label': 'Pendientes', 'color': Colors.orange},
    {'valor': 'en_progreso', 'label': 'En Progreso', 'color': Colors.blue},
    {'valor': 'completado', 'label': 'Completados', 'color': Colors.green},
    {'valor': 'cancelado', 'label': 'Cancelados', 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = _filtros[index];
          final isSelected = filtroActual == filtro['valor'];
          final color = filtro['color'] as Color;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            child: FilterChip(
              label: Text(filtro['label'] as String),
              selected: isSelected,
              onSelected: (_) => onFiltroChanged(filtro['valor'] as String),
              selectedColor: color.withOpacity(0.2),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(color: isSelected ? color : Colors.grey[300]!),
            ),
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(FiltroHeaderDelegate oldDelegate) =>
      oldDelegate.filtroActual != filtroActual;
}