import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.onCustomerContinue,
    required this.onStaffLogin,
    super.key,
  });

  final void Function(BuildContext, String, String) onCustomerContinue;
  final void Function(BuildContext, AuthSession) onStaffLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _course = '';
  String _email = '';
  String _password = '';
  String? _errorMessage;
  bool _isStaffMode = false;
  String _customerMode = 'guest';
  bool _hidePassword = true;
  bool _isSigningIn = false;

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    ApiService.instance.logout();
    widget.onCustomerContinue(context, _name.trim(), _course.trim());
  }

  Future<void> _signInCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });
    try {
      final session = await ApiService.instance.login(_email.trim(), _password);
      if (session.role != 'cliente') {
        ApiService.instance.logout();
        throw const ApiException(
          'Esta cuenta es del personal. Selecciona la opción Personal.',
        );
      }
      if (!mounted) return;
      widget.onCustomerContinue(context, session.name, session.course ?? '');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _registerCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });
    try {
      final session = await ApiService.instance.registerCustomer(
        name: _name.trim(),
        course: _course.trim(),
        email: _email.trim(),
        password: _password,
      );
      if (!mounted) return;
      widget.onCustomerContinue(context, session.name, session.course ?? '');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInStaff() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });
    try {
      final session = await ApiService.instance.login(_email.trim(), _password);
      if (session.role == 'cliente') {
        ApiService.instance.logout();
        throw const ApiException(
          'Esta cuenta es de alumno. Selecciona la opción Alumno.',
        );
      }
      if (!mounted) return;
      widget.onStaffLogin(context, session);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Widget _nameField() => TextFormField(
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    decoration: const InputDecoration(
      labelText: 'Nombre y apellido',
      prefixIcon: Icon(Icons.person_outline),
      border: OutlineInputBorder(),
    ),
    validator: (value) => value == null || value.trim().isEmpty
        ? 'Ingresa tu nombre'
        : value.trim().length > 100
        ? 'El nombre es demasiado largo'
        : null,
    onSaved: (value) => _name = value ?? '',
  );

  Widget _courseField() => TextFormField(
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    decoration: const InputDecoration(
      labelText: 'Curso',
      prefixIcon: Icon(Icons.class_outlined),
      border: OutlineInputBorder(),
    ),
    validator: (value) => value == null || value.trim().isEmpty
        ? 'Ingresa tu curso'
        : value.trim().length > 50
        ? 'El curso es demasiado largo'
        : null,
    onSaved: (value) => _course = value ?? '',
  );

  Widget _emailField() => TextFormField(
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autofillHints: const [AutofillHints.email],
    decoration: const InputDecoration(
      labelText: 'Correo electrónico',
      prefixIcon: Icon(Icons.email_outlined),
      border: OutlineInputBorder(),
    ),
    validator: (value) => value == null || value.trim().isEmpty
        ? 'Ingresa tu correo'
        : !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
        ? 'Ingresa un correo válido'
        : value.trim().length > 254
        ? 'El correo es demasiado largo'
        : null,
    onSaved: (value) => _email = value ?? '',
  );

  Widget _passwordField({required bool isRegistration}) => TextFormField(
    obscureText: _hidePassword,
    autofillHints: [
      isRegistration ? AutofillHints.newPassword : AutofillHints.password,
    ],
    decoration: InputDecoration(
      labelText: 'Contraseña',
      prefixIcon: const Icon(Icons.lock_outline),
      border: const OutlineInputBorder(),
      suffixIcon: IconButton(
        onPressed: () {
          setState(() => _hidePassword = !_hidePassword);
        },
        icon: Icon(
          _hidePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: (value) => value == null || value.isEmpty
        ? 'Ingresa tu contraseña'
        : isRegistration && value.length < 8
        ? 'Usa al menos 8 caracteres'
        : value.length > 128
        ? 'La contraseña es demasiado larga'
        : null,
    onSaved: (value) => _password = value ?? '',
  );

  @override
  Widget build(BuildContext context) {
    final VoidCallback submit = _isStaffMode
        ? _signInStaff
        : switch (_customerMode) {
            'guest' => _continue,
            'login' => _signInCustomer,
            _ => _registerCustomer,
          };
    final buttonLabel = _isStaffMode
        ? 'Ingresar al panel'
        : switch (_customerMode) {
            'guest' => 'Ver menú',
            'login' => 'Ingresar',
            _ => 'Crear cuenta',
          };

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Al Toque',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isStaffMode
                        ? 'Acceso para el personal del buffet'
                        : 'Identifícate para realizar tu pedido',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Alumno'),
                        icon: Icon(Icons.school_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Personal'),
                        icon: Icon(Icons.badge_outlined),
                      ),
                    ],
                    selected: {_isStaffMode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _isStaffMode = selection.first;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (!_isStaffMode) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'guest', label: Text('Invitado')),
                        ButtonSegment(value: 'login', label: Text('Ingresar')),
                        ButtonSegment(
                          value: 'register',
                          label: Text('Registrarme'),
                        ),
                      ],
                      selected: {_customerMode},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _customerMode = selection.first;
                          _errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_isStaffMode) ...[
                    _emailField(),
                    const SizedBox(height: 14),
                    _passwordField(isRegistration: false),
                  ] else if (_customerMode == 'guest') ...[
                    _nameField(),
                    const SizedBox(height: 14),
                    _courseField(),
                  ] else ...[
                    if (_customerMode == 'register') ...[
                      _nameField(),
                      const SizedBox(height: 14),
                      _courseField(),
                      const SizedBox(height: 14),
                    ],
                    _emailField(),
                    const SizedBox(height: 14),
                    _passwordField(isRegistration: _customerMode == 'register'),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSigningIn ? null : submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSigningIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(buttonLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
