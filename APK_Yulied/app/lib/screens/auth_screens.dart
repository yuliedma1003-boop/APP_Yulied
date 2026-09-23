import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/titan_ui.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = context.read<AppState>();
      await app.bootstrap();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => app.isLoggedIn ? const HomeShell() : const LoginScreen(),
          transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _AuthBackground(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DumbbellMark(size: 92),
            SizedBox(height: 18),
            DisplayTitle('TITANFIT'),
            SizedBox(height: 8),
            Text('ENTRENA SIN LÍMITES', style: TextStyle(color: TitanColors.orange, letterSpacing: 3, fontWeight: FontWeight.w800, fontSize: 12)),
            SizedBox(height: 28),
            CircularProgressIndicator(color: TitanColors.orange),
            SizedBox(height: 48),
            Text('Yulied Marcela Lopez', style: TextStyle(color: TitanColors.cream, fontWeight: FontWeight.w700)),
            Text('ADSO · SENA · Ficha 3311983', style: TextStyle(color: TitanColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF140E0C), TitanColors.bg, Color(0xFF0B1620)],
            ),
          ),
        ),
        Positioned(top: -80, right: -60, child: _blob(220, TitanColors.orange.withValues(alpha: 0.16))),
        Positioned(bottom: 80, left: -70, child: _blob(180, TitanColors.amber.withValues(alpha: 0.08))),
        SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child)),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: 'yulied@titanfit.co');
  final password = TextEditingController(text: 'Yulied123*');
  bool busy = false;
  bool hide = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => busy = true);
    try {
      await context.read<AppState>().login(email.text.trim(), password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (e) {
      if (!mounted) return;
      flash(context, e is ApiException ? e.message : 'No se pudo iniciar sesión', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: ListView(
          children: [
            const SizedBox(height: 24),
            const DumbbellMark(size: 70),
            const SizedBox(height: 10),
            const Center(child: DisplayTitle('TITANFIT')),
            const Center(
              child: Text('Gimnasio · reservas · membresías', style: TextStyle(color: TitanColors.muted)),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: hide,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => hide = !hide),
                  icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TitanButton(label: 'Entrar', icon: Icons.login_rounded, onPressed: _submit, busy: busy),
            const SizedBox(height: 12),
            TitanButton(
              label: 'Crear cuenta',
              filled: false,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
            ),
            const SizedBox(height: 22),
            const Text('Cuentas de demostración', style: TextStyle(color: TitanColors.muted, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Cliente Yulied'),
                  onPressed: () {
                    email.text = 'yulied@titanfit.co';
                    password.text = 'Yulied123*';
                  },
                ),
                ActionChip(
                  label: const Text('Administrador'),
                  onPressed: () {
                    email.text = 'admin@titanfit.co';
                    password.text = 'Admin123*';
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Yulied Marcela Lopez · ADSO SENA · Ficha 3311983',
              textAlign: TextAlign.center,
              style: TextStyle(color: TitanColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.length < 6) {
      flash(context, 'Completa nombre, correo y una clave de 6+ caracteres', error: true);
      return;
    }
    if (password.text != confirm.text) {
      flash(context, 'Las contraseñas no coinciden', error: true);
      return;
    }
    setState(() => busy = true);
    try {
      await context.read<AppState>().register(
            name: name.text.trim(),
            email: email.text.trim(),
            password: password.text,
            phone: phone.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      flash(context, e is ApiException ? e.message : 'No se pudo registrar', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: ListView(
          children: [
            const SizedBox(height: 8),
            IconButton(
              alignment: Alignment.centerLeft,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: TitanColors.cream),
            ),
            const DisplayTitle('REGISTRO'),
            const Text('Crea tu cuenta de cliente TitanFit', style: TextStyle(color: TitanColors.muted)),
            const SizedBox(height: 20),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline))),
            const SizedBox(height: 12),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 12),
            TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_reset_outlined))),
            const SizedBox(height: 20),
            TitanButton(label: 'Crear cuenta', icon: Icons.person_add_alt_1, onPressed: _submit, busy: busy),
          ],
        ),
      ),
    );
  }
}
