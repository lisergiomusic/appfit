import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_nav_back_button.dart';

class AlunoSegurancaPage extends StatefulWidget {
  const AlunoSegurancaPage({super.key});

  @override
  State<AlunoSegurancaPage> createState() => _AlunoSegurancaPageState();
}

class _AlunoSegurancaPageState extends State<AlunoSegurancaPage> {
  final String? _email = SupabaseAuthService().currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
        ),
        leading: const AppNavBackButton(),
        title: const Text('Segurança'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          SpacingTokens.screenHorizontalPadding,
          SpacingTokens.screenTopPadding,
          SpacingTokens.screenHorizontalPadding,
          SpacingTokens.screenBottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmailReadOnly(),
            const SizedBox(height: SpacingTokens.sectionGap),
            _buildGroup([
              _buildItem(
                icon: Icons.lock_outline_rounded,
                label: 'Alterar senha',
                onTap: () => _abrirAlterarSenha(context),
              ),
              // TODO: reativar "Alterar e-mail" quando os usuários forem reais.
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailReadOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('E-mail de acesso', style: AppTheme.formLabel),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
          ),
          child: Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: AppColors.labelSecondary.withAlpha(120),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _email ?? '—',
                  style: AppTheme.inputText.copyWith(
                    color: AppColors.labelSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.labelSecondary.withAlpha(60),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroup(List<Widget> items) {
    return Container(
      decoration: AppTheme.premiumCardDecoration,
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 52,
                color: Colors.white.withAlpha(15),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        splashColor: Colors.white.withAlpha(10),
        highlightColor: Colors.white.withAlpha(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.cardPaddingH,
            vertical: 16,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.labelSecondary),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: AppColors.labelPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.labelSecondary.withAlpha(60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirAlterarSenha(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AlterarSenhaSheet(),
    );
  }

}

// ─── Sheet: Alterar senha ────────────────────────────────────────────────────

class _AlterarSenhaSheet extends StatefulWidget {
  const _AlterarSenhaSheet();

  @override
  State<_AlterarSenhaSheet> createState() => _AlterarSenhaSheetState();
}

class _AlterarSenhaSheetState extends State<_AlterarSenhaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _isSaving = false;
  bool _mostrarSenhaAtual = false;
  bool _mostrarNovaSenha = false;
  bool _mostrarConfirmar = false;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await SupabaseAuthService().alterarSenha(
        novaSenha: _novaSenhaController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha alterada com sucesso!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.screenHorizontalPadding,
        SpacingTokens.lg,
        SpacingTokens.screenHorizontalPadding,
        keyboardHeight + SpacingTokens.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alterar senha', style: AppTheme.title1),
            const SizedBox(height: SpacingTokens.sectionGap),
            _buildPasswordField(
              controller: _senhaAtualController,
              label: 'Senha atual',
              visible: _mostrarSenhaAtual,
              onToggle: () => setState(() => _mostrarSenhaAtual = !_mostrarSenhaAtual),
              validator: (v) => v!.isEmpty ? 'Informe a senha atual' : null,
            ),
            const SizedBox(height: SpacingTokens.md),
            _buildPasswordField(
              controller: _novaSenhaController,
              label: 'Nova senha',
              visible: _mostrarNovaSenha,
              onToggle: () => setState(() => _mostrarNovaSenha = !_mostrarNovaSenha),
              validator: (v) {
                if (v!.isEmpty) return 'Informe a nova senha';
                if (v.length < 6) return 'Mínimo de 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: SpacingTokens.md),
            _buildPasswordField(
              controller: _confirmarSenhaController,
              label: 'Confirmar nova senha',
              visible: _mostrarConfirmar,
              onToggle: () => setState(() => _mostrarConfirmar = !_mostrarConfirmar),
              validator: (v) {
                if (v != _novaSenhaController.text) return 'As senhas não coincidem';
                return null;
              },
            ),
            const SizedBox(height: SpacingTokens.sectionGap),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.formLabel),
        const SizedBox(height: SpacingTokens.labelToField),
        TextFormField(
          controller: controller,
          obscureText: !visible,
          enabled: !_isSaving,
          validator: validator,
          style: AppTheme.inputText,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: AppTheme.inputPlaceHolder,
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.labelSecondary.withAlpha(120),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.labelSecondary.withAlpha(120),
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AppColors.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: BorderSide(color: Colors.white.withAlpha(10), width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: BorderSide(color: Colors.white.withAlpha(10), width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: BorderSide(color: Colors.redAccent.withAlpha(100), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
            child: Text(
              'CANCELAR',
              style: AppTheme.navBarAction.copyWith(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.labelSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _isSaving ? null : _salvar();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    'SALVAR',
                    style: AppTheme.navBarAction.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}