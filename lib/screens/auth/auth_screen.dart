import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_errors.dart';
import '../../providers/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../widgets/motion.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signUp = true;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_signUp) {
        await auth.signUp(
          email: _email.text,
          password: _password.text,
          displayName: _name.text.isEmpty ? 'Parent' : _name.text,
        );
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email above, then tap Forgot password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      setState(() => _info = 'Password reset email sent. Check your inbox.');
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          children: [
            Appear(
              duration: AppMotion.slow,
              curve: AppMotion.springy,
              child: Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'N',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            ),
            const SizedBox(height: 16),
            const Appear(
              delay: Duration(milliseconds: 60),
              child: Text(
              'nestly',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.8,
              ),
            ),
            ),
            const SizedBox(height: 6),
            Appear(
              delay: const Duration(milliseconds: 100),
              child: Text(
              _signUp ? 'Create your family account' : 'Welcome back',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSecondary,
              ),
            ),
            ),
            const SizedBox(height: 32),
            Appear(
              delay: const Duration(milliseconds: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            if (_signUp) ...[
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Your name'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (!_signUp) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ],
            if (_info != null) ...[
              const SizedBox(height: 6),
              Text(
                _info!,
                style: const TextStyle(color: AppColors.accentDeep, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.primary,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_signUp ? 'Sign up' : 'Log in'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _signUp = !_signUp;
                        _error = null;
                        _info = null;
                      }),
              child: Text(
                _signUp
                    ? 'Already have an account? Log in'
                    : 'Need an account? Sign up',
              ),
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
