import 'package:flutter/material.dart';

class CadastroPage extends StatefulWidget {
  final String userType;

  const CadastroPage({super.key, required this.userType});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    // Título dinâmico para o usuário saber onde está se cadastrando
    String titulo = widget.userType == 'personal'
        ? 'Novo Personal'
        : 'Novo Aluno';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preencha os dados abaixo para começar.',
                style: TextStyle(fontSize: 16, color: Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 32),

              // Campo de Nome
              _buildTextField(
                label: 'Nome completo',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Campo de E-mail
              _buildTextField(
                label: 'E-mail',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Campo de Senha
              _buildTextField(
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

              // Campo Confirmar Senha
              _buildTextField(
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

              // Botão Cadastrar
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    print(
                      "Tentando cadastrar no Firebase como ${widget.userType}",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFFF5722,
                    ), // Laranja Queimado
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
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

  // Mesmo componente de input que usamos no login, mantendo o padrão visual
  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFFFF5722),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFAAAAAA)),
        prefixIcon: Icon(icon, color: const Color(0xFFAAAAAA)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFFAAAAAA),
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
        ),
      ),
    );
  }
}
