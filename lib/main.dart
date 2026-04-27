import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/firebase_options.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/shared/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await sb.Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  if (kDebugMode) {
    FirebaseFirestore.setLoggingEnabled(true);
  }

  // CONFIGURAÇÃO DE ALTA PERFORMANCE
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await initializeDateFormatting('pt_BR', null);

  runApp(const AppFit());
}

class AppFit extends StatelessWidget {
  const AppFit({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AppFit',
      theme: AppTheme.themeData,
      home: const ChecagemPagina(),
    );
  }
}

class ChecagemPagina extends StatefulWidget {
  const ChecagemPagina({super.key});

  @override
  State<ChecagemPagina> createState() => _ChecagemPaginaState();
}

class _ChecagemPaginaState extends State<ChecagemPagina> {
  final AuthService _authService = AuthService();
  // Guarda o widget uma vez construído para não recriar em rebuilds do auth.
  Widget? _cachedHome;
  String? _cachedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Se já temos home em cache, mostra ele em vez de spinner.
          if (_cachedHome != null) return _cachedHome!;
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final uid = snapshot.data!.uid;
          // Só reconstrói se o uid mudou (login de outro usuário).
          if (_cachedUid != uid) {
            _cachedUid = uid;
            _cachedHome = _UserTypeLoader(
              uid: uid,
              authService: _authService,
            );
          }
          return _cachedHome!;
        }

        // Usuário deslogou — limpa o cache.
        _cachedHome = null;
        _cachedUid = null;
        return const SelecaoPerfilScreen();
      },
    );
  }
}

class _UserTypeLoader extends StatefulWidget {
  final String uid;
  final AuthService authService;

  const _UserTypeLoader({
    required this.uid,
    required this.authService,
  });

  @override
  State<_UserTypeLoader> createState() => _UserTypeLoaderState();
}

class _UserTypeLoaderState extends State<_UserTypeLoader> {
  late final Future<String?> _userTypeFuture;

  @override
  void initState() {
    super.initState();
    // Future criado uma única vez em initState — não recria em rebuilds.
    _userTypeFuture = widget.authService.getUserType(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _userTypeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.labelSecondary, size: 48),
                  const SizedBox(height: 16),
                  const Text('Erro ao carregar perfil.', style: TextStyle(color: AppColors.labelSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => widget.authService.signOut(),
                    child: const Text('Voltar ao login'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return DashboardPage(userType: snapshot.data!);
        }

        return const SelecaoPerfilScreen();
      },
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 42,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'APPFIT',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.labelPrimary,
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
                  color: AppColors.labelSecondary,
                ),
              ),
              const Spacer(flex: 2),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
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