import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/models/branch.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/services/branches_service.dart';
import 'package:servus_app/shared/widgets/loading_widget.dart';
import 'package:servus_app/shared/widgets/error_widget.dart';
import 'package:servus_app/features/branches/create/create_branch_screen.dart';
import 'package:servus_app/features/branches/details/branch_details_screen.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class BranchesDashboardScreen extends StatefulWidget {
  const BranchesDashboardScreen({super.key});

  @override
  State<BranchesDashboardScreen> createState() => _BranchesDashboardScreenState();
}

class _BranchesDashboardScreenState extends State<BranchesDashboardScreen> {
  List<Branch> _branches = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedState;
  bool? _isActive;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBranches() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filter = BranchFilter(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        cidade: _selectedCity,
        estado: _selectedState,
        isActive: _isActive,
      );

      final response = await BranchesService.getBranches(filter: filter);
      if (mounted) {
        setState(() {
          _branches = response.branches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deactivateBranch(String branchId) async {
    if (!mounted) return;
    
    try {
      await BranchesService.deactivateBranch(branchId);
      if (mounted) {
        _loadBranches();
        showSuccess(context, 'Filial desativada com sucesso');
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Erro ao desativar filial: $e');
      }
    }
  }

  void _toggleSearch() {
    if (!mounted) return;
    
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchQuery = '';
        _selectedCity = null;
        _selectedState = null;
        _isActive = null;
        _loadBranches();
      }
    });
  }

  void _showDeactivateConfirmation(Branch branch) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar desativação'),
        content: Text('Tem certeza que deseja desativar a filial ${branch.name}?'),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              _deactivateBranch(branch.branchId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Gerenciar Filiais'),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                key: ValueKey(_isSearchVisible ? 'close' : 'search'),
                _isSearchVisible ? Icons.close : Icons.search,
                color: _isSearchVisible ? context.colors.primary : null,
              ),
            ),
            tooltip: _isSearchVisible ? 'Fechar filtros' : 'Abrir filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros animados
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: _isSearchVisible ? _buildFilters() : const SizedBox.shrink(),
          ),

          // Lista de filiais
          Expanded(
            child: _buildBranchesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!mounted) return;
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBranchScreen(),
            ),
          );
          if (mounted && result == true) {
            _loadBranches();
          }
        },
        icon: const Icon(Icons.business),
        label: const Text('Nova Filial'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Campo de busca com animação
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.0, end: _isSearchVisible ? 1.0 : 0.0),
            builder: (context, value, child) {
              final clampedValue = value.clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, -20 * (1 - clampedValue)),
                child: Opacity(
                  opacity: clampedValue,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar por nome ou descrição',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (_) => _loadBranches(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Filtros adicionais com animação
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.0, end: _isSearchVisible ? 1.0 : 0.0),
            builder: (context, value, child) {
              final clampedValue = value.clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, -20 * (1 - clampedValue)),
                child: Opacity(
                  opacity: clampedValue,
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _isActive == null
                              ? null
                              : (_isActive! ? 'true' : 'false'),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(value: 'true', child: Text('Ativo')),
                            DropdownMenuItem(value: 'false', child: Text('Inativo')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _isActive = value == null ? null : value == 'true';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _selectedCity = value.isEmpty ? null : value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Botões com animação
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.0, end: _isSearchVisible ? 1.0 : 0.0),
            builder: (context, value, child) {
              final clampedValue = value.clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, -20 * (1 - clampedValue)),
                child: Opacity(
                  opacity: clampedValue,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              _loadBranches();
                            }
                          },
                          child: const Text('Aplicar Filtros'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (!mounted) return;
                            
                            setState(() {
                              _searchQuery = '';
                              _selectedCity = null;
                              _selectedState = null;
                              _isActive = null;
                            });
                            _loadBranches();
                          },
                          child: const Text('Limpar'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesList() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return CustomErrorWidget(
        message: _error!,
        onRetry: _loadBranches,
      );
    }

    if (_branches.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadBranches();
      },
      child: ListView.builder(
        itemCount: _branches.length,
        itemBuilder: (context, index) {
          final branch = _branches[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: branch.isActive ? context.colors.primary : Colors.grey,
                child: Icon(
                  Icons.business,
                  color: Colors.white,
                ),
              ),
              title: Text(branch.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (branch.description != null)
                    Text(branch.description!),
                  if (branch.endereco?.fullAddress.isNotEmpty == true)
                    Text(
                      branch.endereco!.fullAddress,
                      style: const TextStyle(fontSize: 12),
                    ),
                  Row(
                    children: [
                      Icon(
                        branch.isActive ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: branch.isActive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        branch.isActive ? 'Ativo' : 'Inativo',
                        style: TextStyle(
                          color: branch.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (!mounted) return;
                  
                  switch (value) {
                    case 'view':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BranchDetailsScreen(branch: branch),
                        ),
                      );
                      break;
                    case 'edit':
                      // TODO: Implementar edição
                      break;
                    case 'deactivate':
                      _showDeactivateConfirmation(branch);
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
                        Text('Ver detalhes'),
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
                  if (branch.isActive)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(Icons.pause_circle, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Desativar', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                ],
              ),
              onTap: () {
                if (!mounted) return;
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BranchDetailsScreen(branch: branch),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma filial cadastrada',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie a primeira filial para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
