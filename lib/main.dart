import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'login_page.dart'; // <-- AQUI ESTAVA O ERRO! Importação adicionada.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AppFit());
}

class AppFit extends StatelessWidget {
  const AppFit({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AppFit',
      theme: AppTheme.darkTheme,
      home: const SelecaoPerfilScreen(),
    );
  }
}

class SelecaoPerfilScreen extends StatelessWidget {
  const SelecaoPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),

              // Logomarca Premium usando as cores do AppTheme
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 42,
                    color: AppTheme.primary, // Substituído pelo Tema
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'APPFIT',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.textPrimary, // Substituído pelo Tema
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text(
                'A sua plataforma',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary, // Substituído pelo Tema
                ),
              ),

              const Spacer(flex: 2),

              // Botão: Sou Personal Trainer (Destaque Principal)
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginPage(userType: 'personal'),
                      ),
                    );
                  },
                  // Não precisamos passar style aqui! O ElevatedButtonTheme do app_theme.dart já cuida de deixar ele Laranja!
                  child: const Text(
                    'Sou personal trainer',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão: Sou Aluno (Secundário, mais discreto)
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginPage(userType: 'aluno'),
                      ),
                    );
                  },
                  // Aqui nós passamos o style apenas para sobrescrever a cor, já que queremos ele Cinza e não Laranja
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceLight,
                  ),
                  child: const Text(
                    'Sou aluno',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
