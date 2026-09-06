import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final TextEditingController _serverCtrl;
  bool _obscure = true;
  bool _showServerField = false;
  bool _signingIn = false;

  @override
  void initState() {
    super.initState();
    _serverCtrl = TextEditingController(text: context.read<AppState>().apiBaseUrl);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _serverCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState state) async {
    setState(() => _signingIn = true);
    await state.login(_usernameCtrl.text, _passwordCtrl.text);
    if (mounted) setState(() => _signingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(13)),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.gold, size: 24),
                  ),
                  const SizedBox(height: 14),
                  Text(state.data.business.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  const Text('Staff sign in', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  const SizedBox(height: 24),
                  AppCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameCtrl,
                          decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline, size: 20)),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          onSubmitted: (_) => _submit(state),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        if (state.loginError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(state.loginError, style: const TextStyle(color: AppColors.brick, fontSize: 13)),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signingIn ? null : () => _submit(state),
                            child: _signingIn
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => setState(() => _showServerField = !_showServerField),
                    icon: const Icon(Icons.dns_outlined, size: 15),
                    label: Text(_showServerField ? 'Hide server settings' : 'Server settings'),
                  ),
                  if (_showServerField)
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'The address of your backend server. Only needs to be changed if you\'re not running it on this device.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _serverCtrl,
                            decoration: const InputDecoration(labelText: 'Server URL', hintText: 'http://10.0.2.2:4000/api'),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await state.updateApiBaseUrl(_serverCtrl.text);
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('Server address saved.')));
                                }
                              },
                              child: const Text('Save server address'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'First time on a fresh server? Sign in with admin / admin123, then change it under Staff accounts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
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
