import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/aluno_service.dart';
import '../../../core/services/personal_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bar_divider.dart';
import '../../alunos/shared/widgets/app_avatar.dart';
import '../../alunos/personal/pages/personal_log_detalhe_page.dart';

class PersonalAtividadeRecentePage extends StatefulWidget {
  final PersonalService personalService;

  const PersonalAtividadeRecentePage({super.key, required this.personalService});

  @override
  State<PersonalAtividadeRecentePage> createState() =>
      _PersonalAtividadeRecentePageState();
}

class _PersonalAtividadeRecentePageState
    extends State<PersonalAtividadeRecentePage> {
  static const _pageSize = 20;

  final _items = <AtividadeRecenteItem>[];
  final _scrollController = ScrollController();

  dynamic _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final result = await widget.personalService.fetchAtividadePage(
      limit: _pageSize,
      startAfter: _lastDoc,
    );

    setState(() {
      _items.addAll(result.items);
      _lastDoc = result.lastDoc;
      _hasMore = result.lastDoc != null;
      _isLoading = false;
    });
  }

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return 'Há ${diff.inDays}d';
    return DateFormat('d MMM', 'pt_BR').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: const Text('Atividade recente'),
        bottom: const AppBarDivider(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Nenhum treino concluído ainda.',
          style: AppTheme.cardSubtitle,
        ),
      );
    }

    // +1 para o footer de loading / fim de lista
    final itemCount = _items.length + 1;

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingScreen,
        vertical: SpacingTokens.screenTopPadding,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return _buildFooter();
        }

        final item = _items[index];
        final isLast = index == _items.length - 1;

        return _AtividadeCard(
          item: item,
          tempoRelativo: _tempoRelativo(item.dataHora),
          isFirst: index == 0,
          isLast: isLast && !_hasMore,
        );
      },
    );
  }

  Widget _buildFooter() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasMore && _items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Todos os registros carregados', style: AppTheme.caption),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _AtividadeCard extends StatelessWidget {
  final AtividadeRecenteItem item;
  final String tempoRelativo;
  final bool isFirst;
  final bool isLast;

  const _AtividadeCard({
    required this.item,
    required this.tempoRelativo,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(AppTheme.radiusLG) : Radius.zero,
          bottom: isLast ? Radius.circular(AppTheme.radiusLG) : Radius.zero,
        ),
        border: Border(
          top: isFirst
              ? BorderSide(color: Colors.white.withAlpha(5))
              : BorderSide.none,
          left: BorderSide(color: Colors.white.withAlpha(5)),
          right: BorderSide(color: Colors.white.withAlpha(5)),
          bottom: isLast
              ? BorderSide(color: Colors.white.withAlpha(5))
              : BorderSide.none,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonalLogDetalhePage(item: item),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: CardTokens.padding,
              child: Row(
                children: [
                  AppAvatar(
                    name: item.alunoNome,
                    photoUrl: item.alunoPhotoUrl,
                    radius: AvatarTokens.md,
                    showBorder: false,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.alunoNome, style: AppTheme.cardTitle),
                        const SizedBox(height: SpacingTokens.titleToSubtitle),
                        Text(
                          'Concluiu ${item.sessaoNome}',
                          style: AppTheme.cardSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tempoRelativo, style: AppTheme.caption),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.labelSecondary.withAlpha(80),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.separator,
                ),
              ),
          ],
        ),
      ),
    );
  }
}