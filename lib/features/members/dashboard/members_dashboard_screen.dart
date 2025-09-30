import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/widgets/scroll_reveal_animation.dart';
import 'package:servus_app/core/widgets/shimmer_widget.dart';
import 'package:servus_app/services/members_service.dart';
import 'package:servus_app/shared/widgets/loading_widget.dart';
import 'package:servus_app/shared/widgets/error_widget.dart';
import 'package:servus_app/features/members/create/create_member_screen.dart';
import 'package:servus_app/features/members/details/member_details_screen.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class MembersDashboardScreen extends StatefulWidget {
  const MembersDashboardScreen({super.key});

  @override
  State<MembersDashboardScreen> createState() => _MembersDashboardScreenState();
}

class _MembersDashboardScreenState extends State<MembersDashboardScreen> {
  List<Member> _members = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedBranchId;
  String? _selectedMinistryId;
  String? _selectedRole;
  bool? _isActive;
  bool _isSearchVisible = false;
  
  // Controllers para animações
  

  @override
  void initState() {
    super.initState();
    
    // Inicializar animações
    
    
    
    _loadMembers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filter = MemberFilter(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        branchId: _selectedBranchId,
        ministryId: _selectedMinistryId,
        role: _selectedRole,
        isActive: _isActive,
      );

      final response = await MembersService.getMembers(filter: filter);
      if (mounted) {
        setState(() {
          _members = response.members;
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

  Future<void> _deleteMember(String id) async {
    if (!mounted) return;

    try {
      await MembersService.deleteMember(id, context);
      if (mounted) {
        _loadMembers(); // Recarregar lista
        showSuccess(context, 'Membro deletado com sucesso');
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Erro ao deletar membro: $e');
      }
    }
  }


  void _toggleSearch() {
    if (!mounted) return;

    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchQuery = '';
        _selectedBranchId = null;
        _selectedMinistryId = null;
        _selectedRole = null;
        _isActive = null;
        _loadMembers();
      }
    });
  }

  String _normalizeRole(String role) {
    switch (role) {
      case 'tenant_admin':
        return 'Admin da Igreja';
      case 'branch_admin':
        return 'Admin do Campus';
      case 'leader':
        return 'Líder de Ministério';
      case 'volunteer':
        return 'Voluntário';
      default:
        return role;
    }
  }

  void _showDeleteConfirmation(Member member) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão', style: TextStyle(color: context.colors.onSurface)),
        content:
            Text('Tem certeza que deseja deletar o membro ${member.name}?'),
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
              _deleteMember(member.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
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
        title: const Text('Gerenciar Membros'),
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

          // Lista de membros
          Expanded(
            child: _buildMembersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!mounted) return;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateMemberScreen(),
            ),
          );
          if (mounted && result == true) {
            _loadMembers();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Membro'),
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
                      labelText: 'Buscar por nome ou email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (_) => _loadMembers(),
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
                            DropdownMenuItem(
                                value: 'true', child: Text('Ativo')),
                            DropdownMenuItem(
                                value: 'false', child: Text('Inativo')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _isActive =
                                  value == null ? null : value == 'true';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedRole,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(
                                value: 'tenant_admin',
                                child: Text('Admin da Igreja')),
                            DropdownMenuItem(
                                value: 'branch_admin',
                                child: Text('Admin do Campus')),
                            DropdownMenuItem(
                                value: 'leader', child: Text('Líder de Ministério')),
                            DropdownMenuItem(
                                value: 'volunteer', child: Text('Voluntário')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value;
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
                              _loadMembers();
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
                              _selectedBranchId = null;
                              _selectedMinistryId = null;
                              _selectedRole = null;
                              _isActive = null;
                            });
                            _loadMembers();
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

  Widget _buildMembersList() {
    if (_isLoading) {
      return const ShimmerList(
        itemCount: 8,
        itemHeight: 100,
      );
    }

    if (_error != null) {
      return CustomErrorWidget(
        message: _error!,
        onRetry: _loadMembers,
      );
    }

    if (_members.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadMembers();
      },
      child: ListView.builder(
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          
          return FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      onTap: () => _navigateToMemberDetails(member),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  member.isActive ? context.colors.primary : Colors.grey,
                              child: Text(
                                member.name[0].toUpperCase(),
                                style: TextStyle(color: context.colors.onPrimary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (!member.isActive)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _normalizeRole(member.role), 
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: member.isActive ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    member.isActive ? 'Ativo' : 'Inativo',
                                    style: TextStyle(
                                      color: member.isActive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleMemberAction(value, member),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, size: 20),
                                  SizedBox(width: 8),
                                  Text('Ver Detalhes'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Deletar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                      ),
                    ),
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
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum membro cadastrado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie o primeiro membro para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }


  /// Navegar para detalhes do membro
  void _navigateToMemberDetails(Member member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberDetailsScreen(member: member),
      ),
    );
  }

  /// Manipular ações do menu do membro
  void _handleMemberAction(String action, Member member) {
    switch (action) {
      case 'view':
        _navigateToMemberDetails(member);
        break;
      case 'edit':
        // TODO: Implementar edição
        showInfo(context, 'Edição de membro em desenvolvimento');
        break;
      case 'delete':
        _showDeleteConfirmation(member);
        break;
    }
  }
}
