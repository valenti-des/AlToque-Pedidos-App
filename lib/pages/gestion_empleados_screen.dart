import 'package:flutter/material.dart';

import '../models/empleado.dart';
import '../services/api_service.dart';

class GestionEmpleadosScreen extends StatefulWidget {
  const GestionEmpleadosScreen({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  State<GestionEmpleadosScreen> createState() => _GestionEmpleadosScreenState();
}

class _GestionEmpleadosScreenState extends State<GestionEmpleadosScreen> {
  List<Empleado> _employees = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<bool> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final employees = await ApiService.instance.getEmployees();
      if (!mounted) return false;
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
      return false;
    }
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var hidePassword = true;
    var saving = false;
    String? errorMessage;

    try {
      final created = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Agregar empleado'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)
                          ? null
                          : 'Ingresa un correo válido';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      helperText: 'Mínimo 8 caracteres',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setDialogState(() => hidePassword = !hidePassword),
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        (value?.length ?? 0) >= 8 && (value?.length ?? 0) <= 128
                        ? null
                        : 'Usa entre 8 y 128 caracteres',
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          saving = true;
                          errorMessage = null;
                        });
                        try {
                          await ApiService.instance.createEmployee(
                            emailController.text.trim(),
                            passwordController.text,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (error) {
                          setDialogState(() {
                            saving = false;
                            errorMessage = error.toString();
                          });
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear usuario'),
              ),
            ],
          ),
        ),
      );
      if (created == true && mounted) {
        final refreshed = await _loadEmployees();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              refreshed
                  ? 'Empleado creado correctamente.'
                  : 'Empleado creado, pero no se pudo actualizar la lista.',
            ),
          ),
        );
      }
    } finally {
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _confirmDelete(Empleado employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar empleado'),
        content: Text('¿Quieres desactivar la cuenta de ${employee.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar usuario'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await ApiService.instance.deleteEmployee(employee.id);
      final refreshed = await _loadEmployees();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refreshed
                ? 'Cuenta de empleado desactivada.'
                : 'Cuenta desactivada, pero no se pudo actualizar la lista.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la cuenta: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de empleados'),
        actions: [
          IconButton(
            tooltip: 'Actualizar lista',
            onPressed: _isLoading ? null : _loadEmployees,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudo cargar el personal.'),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _loadEmployees,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadEmployees,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GestureDetector(
                    onDoubleTap: _isSaving ? null : _showCreateDialog,
                    child: Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.person_add_alt_1, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Agregar empleado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('Doble toque para crear una cuenta'),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Personal activo (${_employees.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_employees.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Todavía no hay empleados registrados.'),
                      ),
                    )
                  else
                    for (final employee in _employees)
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(employee.name),
                          subtitle: Text(employee.email),
                          trailing: IconButton(
                            tooltip: 'Eliminar usuario ${employee.email}',
                            onPressed: _isSaving
                                ? null
                                : () => _confirmDelete(employee),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}
