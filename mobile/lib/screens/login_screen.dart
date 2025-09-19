import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isRegister = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Solo Journey', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                if (_isRegister)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: '昵称'),
                    validator: (value) => value == null || value.isEmpty ? '请输入昵称' : null,
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: '邮箱'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@') ? null : '请输入正确邮箱',
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: '密码'),
                  obscureText: true,
                  validator: (value) => value != null && value.length >= 6 ? null : '密码至少6位',
                ),
                const SizedBox(height: 24),
                if (state.error != null)
                  Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: state.loading ? null : () => _submit(context),
                  child: Text(_isRegister ? '注册' : '登录'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isRegister = !_isRegister),
                  child: Text(_isRegister ? '已有账号？去登录' : '没有账号？去注册'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    try {
      if (_isRegister) {
        await appState.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('注册成功，请登录')),
          );
          setState(() => _isRegister = false);
        }
      } else {
        await appState.login(_emailController.text, _passwordController.text);
      }
    } catch (_) {
      // error handled in state
    }
  }
}
