import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Nova importação do Firestore!
import 'theme/app_theme.dart';
import 'dashboard_page.dart';

class CadastroPage extends StatefulWidget {
  final String userType;

  const CadastroPage({super.key, required this.userType});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _cadastrarUsuario() async {
    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As palavras-passe não coincidem!')),
      );
      return;
    }

    // Validação extra para garantir que o nome foi preenchido
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduza o seu nome.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Cria a conta no Firebase Auth (E-mail e Palavra-passe)
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text.trim(),
          );

      // 2. Apanha o ID único gerado pelo Google para este utilizador
      String uid = userCredential.user!.uid;

      // 3. Guarda os dados completos no Firestore na coleção 'usuarios'
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'tipoUsuario': widget.userType, // 'personal' ou 'aluno'
        'dataCriacao':
            FieldValue.serverTimestamp(), // Regista a data e hora exata
      });

      // Se tudo correu bem, navega para a Dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(userType: widget.userType),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Ocorreu um erro no registo.';
      if (e.code == 'weak-password') {
        mensagemErro = 'A palavra-passe fornecida é muito fraca.';
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
    } catch (e) {
      // Caso ocorra um erro ao guardar no Firestore
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao guardar os dados: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                controller: _nomeController,
                label: 'Nome completo',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'E-mail',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _senhaController,
                label: 'Palavra-passe',
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
                controller: _confirmarSenhaController,
                label: 'Confirmar Palavra-passe',
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
                  onPressed: _isLoading ? null : _cadastrarUsuario,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registar',
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

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
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
