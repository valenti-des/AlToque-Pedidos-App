import 'package:flutter/material.dart';

import '../models/pedido.dart';
import '../services/api_service.dart';

class HistorialBuffetScreen extends StatefulWidget {
  const HistorialBuffetScreen({super.key});

  @override
  State<HistorialBuffetScreen> createState() => _HistorialBuffetScreenState();
}

class _HistorialBuffetScreenState extends State<HistorialBuffetScreen> {
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _category = 'Todos';
  List<Pedido> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await ApiService.instance.getBuffetHistory(
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  Future<void> _pickDate(bool isStart) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
    );
    if (selected != null) {
      setState(() => isStart ? _startDate = selected : _endDate = selected);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial del buffet')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Alumno, DNI/curso o código',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Buscar',
                      onPressed: _load,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(true),
                        child: Text(
                          _startDate == null
                              ? 'Desde'
                              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(false),
                        child: Text(
                          _endDate == null
                              ? 'Hasta'
                              : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      const ['Todos', 'Comidas', 'Bebidas', 'Snacks', 'Dulces']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _orders.isEmpty
                ? const Center(child: Text('No hay pedidos históricos'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return Card(
                        child: ListTile(
                          title: Text(order.formattedPickupCode),
                          subtitle: Text(
                            '${order.customerName} · ${order.status.label}\n'
                            '${order.items.length} productos · \$${order.total.toStringAsFixed(2)}\n'
                            'Realizado: ${_formatDateTime(order.createdAt).replaceAll('\n', ' ')}\n'
                            'Estado actualizado: ${_formatDateTime(order.statusUpdatedAt)}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Sin fecha';
  final date = value.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year}\n$hour:$minute';
}
