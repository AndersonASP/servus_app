import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_lista_controller.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';

class MinisterioListScreen extends StatefulWidget {
  const MinisterioListScreen({super.key});

  @override
  State<MinisterioListScreen> createState() => _MinisterioListScreenState();
}

class _MinisterioListScreenState extends State<MinisterioListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final MinisterioListController _controller;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = MinisterioListController();
    _controller.carregarMinisterios();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verifica se há parâmetro de refresh na URL
    final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
    if (uri.queryParameters['refresh'] == 'true') {
      // Recarrega a lista quando vem da criação/edição
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.carregarMinisterios(refresh: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_controller.hasMorePages && !_controller.isLoading) {
        _controller.carregarMaisMinisterios();
      }
    }
  }

  void _toggleSearch() {
    if (_isSearchVisible) {
      _closeSearch();
    } else {
      setState(() {
        _isSearchVisible = true;
      });
    }
  }

  void _closeSearch() {
    setState(() {
      _isSearchVisible = false;
      _searchController.clear();
      _controller.limparFiltros();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/leader/dashboard'),
            ),
            title: Text(
              'Ministérios',
              style: context.textStyles.titleLarge
                  ?.copyWith(color: context.colors.onSurface),
            ),
            actions: [
              // Botão de busca
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    key: ValueKey(_isSearchVisible ? 'close' : 'search'),
                    _isSearchVisible ? Icons.close : Icons.search,
                    color: _isSearchVisible ? context.colors.primary : null,
                  ),
                ),
                onPressed: _toggleSearch,
                tooltip: _isSearchVisible ? 'Fechar busca' : 'Abrir busca',
              ),
              // Botão de filtros
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  switch (value) {
                    case 'ativos':
                      _controller.filtrarPorStatus('ativos');
                      break;
                    case 'inativos':
                      _controller.filtrarPorStatus('inativos');
                      break;
                    case 'todos':
                      _controller.filtrarPorStatus('todos');
                      break;
                    case 'limpar':
                      _controller.limparFiltros();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'ativos',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: _controller.filterStatus == 'ativos'
                              ? context.colors.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('Apenas Ativos'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'inativos',
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          color: _controller.filterStatus == 'inativos'
                              ? context.colors.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('Apenas Inativos'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'todos',
                    child: Row(
                      children: [
                        Icon(
                          Icons.list,
                          color: _controller.filterStatus == 'todos'
                              ? context.colors.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('Todos'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'limpar',
                    child: Row(
                      children: [
                        Icon(Icons.clear),
                        SizedBox(width: 8),
                        Text('Limpar Filtros'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: FabSafeScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Barra de busca animada
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isSearchVisible ? 80.0 : 0.0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isSearchVisible ? 1.0 : 0.0,
                    child: Container(
                      child: TextField(
                        controller: _searchController,
                        autofocus: _isSearchVisible,
                        decoration: InputDecoration(
                          hintText: 'Buscar ministérios...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _closeSearch,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _controller.buscarMinisterios(value);
                          } else {
                            _controller.limparFiltros();
                          }
                        },
                        onSubmitted: (value) {
                          // Fecha o campo de busca se estiver vazio
                          if (value.isEmpty) {
                            _closeSearch();
                          }
                        },
                        onTapOutside: (event) {
                          // Fecha o campo de busca se estiver vazio
                          if (_searchController.text.isEmpty) {
                            _closeSearch();
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // Contadores e informações - só aparece se existirem ministérios e não estiver buscando
                if (_controller.ministerios.isNotEmpty &&
                    !_controller.isLoading &&
                    !_isSearchVisible) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        if (_controller.totalPages > 1)
                          Text(
                            'Página ${_controller.currentPage} de ${_controller.totalPages}',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Indicador de busca ativa
                if (_isSearchVisible && _searchController.text.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 16,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Buscando por: "${_searchController.text}"',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_controller.ministerios.length} resultado(s)',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Lista de ministérios
                _controller.isLoading && _controller.ministerios.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.ministerios.isEmpty
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: _buildEmptyState(context),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                _controller.carregarMinisterios(refresh: true),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _controller.ministerios.length +
                                  (_controller.hasMorePages ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                if (index == _controller.ministerios.length) {
                                  return _buildLoadingMore();
                                }

                                final ministerio =
                                    _controller.ministerios[index];
                                return _buildMinistryCard(context, ministerio);
                              },
                            ),
                          ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
            elevation: 8,
            label: Text(
              'Novo',
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              context.push('/leader/ministerio/form');
            },
            icon: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildMinistryCard(BuildContext context, dynamic ministerio) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor:
              ministerio.isActive ? context.colors.primary : Colors.grey,
          child: Icon(
            Icons.groups,
            color:
                ministerio.isActive ? context.colors.onPrimary : Colors.white,
          ),
        ),
        title: Text(
          ministerio.name, // Usando o campo correto do backend
          style: context.textStyles.titleMedium?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ministerio.description != null &&
                ministerio.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ministerio.description,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  ministerio.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: ministerio.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  ministerio.isActive ? 'Ativo' : 'Inativo',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: ministerio.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${ministerio.ministryFunctions.length} ${ministerio.ministryFunctions.length == 1 ? 'função' : 'funções'}',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Switch de status
            Transform.scale(
              scale: 0.75,
              child: _buildSwitch(ministerio),
            ),

            // Menu de ações
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.push('/leader/ministerio/form', extra: ministerio);
                    break;
                  case 'view':
                    context
                        .push('/leader/ministerio-detalhes/${ministerio.id}');
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context, ministerio);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Ver Detalhes'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          context.push('/leader/ministerio-detalhes/${ministerio.id}');
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum ministério encontrado',
            textAlign: TextAlign.center,
            style: context.textStyles.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie o primeiro ministério para começar',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          // ElevatedButton.icon(
          //   onPressed: () => context.push('/leader/ministerio/form'),
          //   icon: const Icon(Icons.add),
          //   label: const Text('Criar Ministério'),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: context.colors.primary,
          //     foregroundColor: context.colors.onPrimary,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSwitch(dynamic ministerio) {
    return _MinistrySwitch(
      ministerio: ministerio,
      controller: _controller,
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic ministerio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar exclusão',
          style: context.textStyles.titleLarge
              ?.copyWith(color: context.colors.onSurface),
        ),
        content: Text(
            'Tem certeza que deseja excluir o ministério "${ministerio.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.removerMinisterio(ministerio.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _MinistrySwitch extends StatefulWidget {
  final dynamic ministerio;
  final MinisterioListController controller;

  const _MinistrySwitch({
    required this.ministerio,
    required this.controller,
  });

  @override
  State<_MinistrySwitch> createState() => _MinistrySwitchState();
}

class _MinistrySwitchState extends State<_MinistrySwitch> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.ministerio.isActive;
  }

  @override
  void didUpdateWidget(_MinistrySwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ministerio.id != widget.ministerio.id) {
      _isActive = widget.ministerio.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _isActive,
      onChanged: widget.controller.isUpdating
          ? null
          : (value) async {
              setState(() {
                _isActive = value;
              });
              
              try {
                await widget.controller.alterarStatus(widget.ministerio.id, value);
              } catch (e) {
                // Reverte em caso de erro
                setState(() {
                  _isActive = !value;
                });
              }
            },
      activeThumbColor: ServusColors.success,
      inactiveThumbColor: Colors.red,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
