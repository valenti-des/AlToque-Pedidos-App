import 'package:flutter/material.dart';

import '../models/employee_stats.dart';
import '../services/api_service.dart';

class EstadisticasEmpleadosScreen extends StatefulWidget {
  const EstadisticasEmpleadosScreen({super.key});

  @override
  State<EstadisticasEmpleadosScreen> createState() =>
      _EstadisticasEmpleadosScreenState();
}

class _EstadisticasEmpleadosScreenState
    extends State<EstadisticasEmpleadosScreen> {
  bool _loading = true;
  String? _error;
  List<EmployeeStats> _stats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await ApiService.instance.getEmployeeStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Desempeño de empleados')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _stats.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final stat = _stats[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(stat.email),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _Metric(
                                  label: 'Entregadas',
                                  value: '${stat.delivered}',
                                  color: Colors.green,
                                ),
                              ),
                              Expanded(
                                child: _Metric(
                                  label: 'Canceladas',
                                  value: '${stat.cancelled}',
                                  color: Colors.red,
                                ),
                              ),
                              Expanded(
                                child: _Metric(
                                  label: 'Efectividad',
                                  value:
                                      '${stat.effectiveness.toStringAsFixed(1)}%',
                                  color: const Color(0xFF0877F9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(label, textAlign: TextAlign.center),
    ],
  );
}
