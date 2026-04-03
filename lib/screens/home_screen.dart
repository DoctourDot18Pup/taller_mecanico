import 'package:flutter/material.dart';
import 'ordenes_screen.dart';
import 'clientes_screen.dart';
import 'catalogo_screen.dart';
import 'estadisticas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _catalogoKey = GlobalKey<CatalogoScreenState>();
  final _statsKey = GlobalKey<EstadisticasScreenState>();

  late final List<Widget> _screens = [
    const OrdenesScreen(),
    const ClientesScreen(),
    CatalogoScreen(key: _catalogoKey),
    EstadisticasScreen(key: _statsKey),
  ];

  void _onTabSelected(int i) {
    setState(() => _index = i);
    if (i == 2) _catalogoKey.currentState?.reload();
    if (i == 3) _statsKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle),
            label: 'Órdenes',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
        ],
      ),
    );
  }
}
