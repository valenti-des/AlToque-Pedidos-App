import 'package:flutter/material.dart';

import 'gestion_empleados_screen.dart';
import 'historial_buffet_screen.dart';
import 'estadisticas_empleados_screen.dart';
import 'tablero_buffet_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AdminActionCard(
            icon: Icons.receipt_long_outlined,
            title: 'Pedidos del buffet',
            description: 'Ver comandas y actualizar su estado',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TableroBuffetScreen(
                  isAdmin: true,
                  onSignOut: onSignOut,
                  onManageEmployees: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          GestionEmpleadosScreen(onSignOut: onSignOut),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AdminActionCard(
            icon: Icons.people_alt_outlined,
            title: 'Gestionar empleados',
            description: 'Crear y desactivar cuentas del personal',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GestionEmpleadosScreen(onSignOut: onSignOut),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AdminActionCard(
            icon: Icons.history,
            title: 'Historial del buffet',
            description: 'Consultar pedidos entregados y cancelados',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const HistorialBuffetScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AdminActionCard(
            icon: Icons.analytics_outlined,
            title: 'Estadísticas de empleados',
            description: 'Medir entregas, cancelaciones y efectividad',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EstadisticasEmpleadosScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
