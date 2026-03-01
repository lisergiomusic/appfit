import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importante: O pacote de autenticação!
import 'theme/app_theme.dart';
import 'dashboard_page.dart';

class CadastroPage extends StatefulWidget {
  final String userType;

  const CadastroPage({super.key, required this.userType});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  // 1. Criando os "espiões" para ler o que o usuário digita
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false; // 2. Variável para mostrar a bolinha de carregamento

  // 3. A nossa função mágica que conversa com o Firebase
  Future<void> _cadastrarUsuario() async {
    // Verificação básica: as senhas batem?
    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não conferem!')));
      return;
    }

    setState(() {
      _isLoading = true; // Liga o carregamento
    });

    try {
      // Tenta criar o usuário no Google
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      // Se deu certo, vai para a Dashboard!
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(userType: widget.userType),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Se o Firebase reclamar (ex: e-mail já existe, senha fraca), mostramos o erro
      String mensagemErro = 'Ocorreu um erro no cadastro.';
      if (e.code == 'weak-password') {
        mensagemErro = 'A senha fornecida é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        mensagemErro = 'Já existe uma conta com este e-mail.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErro),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading =
              false; // Desliga o carregamento independente se deu erro ou sucesso
        });
      }
    }
  }

  // 4. Limpando a memória quando a tela for fechada (boa prática)
  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String titulo = widget.userType == 'personal'
        ? 'Novo Personal'
        : 'Novo Aluno';

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              Text(
                'Criar Conta\n$titulo',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preencha os dados abaixo para começar.',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                controller: _nomeController, // Ligando o controlador
                label: 'Nome completo',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController, // Ligando o controlador
                label: 'E-mail',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _senhaController, // Ligando o controlador
                label: 'Senha',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                onTogglePassword: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _confirmarSenhaController, // Ligando o controlador
                label: 'Confirmar Senha',
                icon: Icons.lock_reset_outlined,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onTogglePassword: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  // Só permite clicar se não estiver carregando
                  onPressed: _isLoading ? null : _cadastrarUsuario,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        ) // Bolinha girando
                      : const Text(
                          'Cadastrar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Atualizamos a função para aceitar o 'controller'
  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextEditingController? controller, // Adicionado aqui!
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller, // E repassado para o TextField real
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: AppTheme.textPrimary),
      cursorColor: AppTheme.primary,
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
