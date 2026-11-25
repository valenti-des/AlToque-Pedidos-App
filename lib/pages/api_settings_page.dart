import 'package:flutter/material.dart';

import '../basedate.dart';

class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  late final TextEditingController _urlController;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ApiConfig.setBaseUrl(_urlController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar conexión')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Dirección de la API',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para conectarte desde el celular, escribe la IP de la computadora '
            'y el puerto 8080. Ambos dispositivos deben estar en la misma red Wi-Fi.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _isSaving ? null : _save(),
            decoration: InputDecoration(
              labelText: 'URL de la API',
              hintText: 'http://192.168.1.25:8080',
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar dirección'),
          ),
        ],
      ),
    );
  }
}
