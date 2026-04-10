import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../dashboard/shared/dashboard_page.dart';

class PrimeiroAcessoPage extends StatefulWidget {
  const PrimeiroAcessoPage({super.key});

  @override
  State<PrimeiroAcessoPage> createState() => _PrimeiroAcessoPageState();
}

class _PrimeiroAcessoPageState extends State<PrimeiroAcessoPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscureSenha = true;
  bool _obscureConfirmar = true;
  bool _isLoading = false;

  Future<void> _criarConta() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmar = _confirmarSenhaController.text.trim();

    if (email.isEmpty || senha.isEmpty || confirmar.isEmpty) {
      _showError('Preencha todos os campos.');
      return;
    }

    if (senha != confirmar) {
      _showError('As senhas não coincidem.');
      return;
    }

    if (senha.length < 6) {
      _showError('A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.primeiroAcessoAluno(email: email, password: senha);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardPage(userType: 'aluno'),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Primeiro acesso',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.labelPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use o e-mail que seu personal cadastrou para você e crie uma senha.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.labelSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              _buildTextField(
                controller: _emailController,
                label: 'E-mail cadastrado pelo personal',
                icon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _senhaController,
                label: 'Criar senha',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureSenha,
                onTogglePassword: () =>
                    setState(() => _obscureSenha = !_obscureSenha),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmarSenhaController,
                label: 'Confirmar senha',
                icon: Icons.lock_reset_outlined,
                isPassword: true,
                obscureText: _obscureConfirmar,
                onTogglePassword: () =>
                    setState(() => _obscureConfirmar = !_obscureConfirmar),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _criarConta,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Criar minha conta',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.labelPrimary),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onTogglePassword,
              )
            : null,
      ),
    );
  }
}
