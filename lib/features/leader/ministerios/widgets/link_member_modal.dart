import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:servus_app/services/members_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class LinkMemberModal extends StatefulWidget {
  final MinisterioDetalhesController controller;

  const LinkMemberModal({
    super.key,
    required this.controller,
  });

  @override
  State<LinkMemberModal> createState() => _LinkMemberModalState();
}

class _LinkMemberModalState extends State<LinkMemberModal> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Member> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMoreResults = false;
  String _selectedRole = 'volunteer';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.length >= 2) {
      _searchMembers();
    } else if (_searchController.text.isEmpty) {
      _loadMembers();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMembers();
    }
  }

  Future<void> _loadMembers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
    });

    try {
      final response = await MembersService.getMembers(
        filter: MemberFilter(
          page: _currentPage,
          limit: 20,
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
        ),
        context: context,
      );

      // Debug: Log da resposta

      setState(() {
        _searchResults = response.members;
        _hasMoreResults = response.members.length >= 20;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchMembers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
    });

    try {
      final response = await MembersService.getMembers(
        filter: MemberFilter(
          page: 1,
          limit: 20,
          search: _searchController.text,
        ),
        context: context,
      );

      setState(() {
        _searchResults = response.members;
        _hasMoreResults = response.members.length >= 20;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMembers() async {
    if (_isLoading || !_hasMoreResults) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      _currentPage++;
      final response = await MembersService.getMembers(
        filter: MemberFilter(
          page: _currentPage,
          limit: 20,
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
        ),
        context: context,
      );

      setState(() {
        _searchResults.addAll(response.members);
        _hasMoreResults = response.members.length >= 20;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _linkMember(Member member) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await widget.controller.vincularMembro(
        member.id, 
        _selectedRole,
      );
      
      if (mounted) {
        if (success) {
          ServusSnackQueue.addToQueue(
            context: context,
            message: '${member.name} vinculado ao ministério como ${_selectedRole == 'leader' ? 'líder' : 'voluntário'}!',
            type: ServusSnackType.success,
          );
          Navigator.of(context).pop();
        } else {
          ServusSnackQueue.addToQueue(
            context: context,
            message: 'Erro ao vincular membro ao ministério',
            type: ServusSnackType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ServusSnackQueue.addToQueue(
          context: context,
          message: 'Erro ao vincular membro: $e',
          type: ServusSnackType.error,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.colors.surface,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: context.colors.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vincular Membro ao Ministério',
                      style: context.textStyles.titleLarge?.copyWith(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: context.colors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Search and Role Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar membros...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadMembers();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: context.colors.surface,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Role Selection
                  Row(
                    children: [
                      Text(
                        'Função: ',
                        style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(
                              value: 'volunteer',
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                            const Text('Voluntário'),
                            const SizedBox(width: 16),
                            Radio<String>(
                              value: 'leader',
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                            const Text('Líder'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading && _searchResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar membros',
              style: context.textStyles.titleMedium?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMembers,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
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
              'Nenhum membro encontrado',
              style: context.textStyles.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Digite pelo menos 2 caracteres para pesquisar'
                  : 'Nenhum membro corresponde à sua pesquisa',
              style: context.textStyles.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length + (_hasMoreResults ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _searchResults.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final member = _searchResults[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildMemberCard(Member member) {
    final name = member.name;
    final email = member.email;
    final phone = member.phone;
    final isActive = member.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.colors.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.person,
            color: context.colors.primary,
          ),
        ),
        title: Text(
          name,
          style: context.textStyles.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty)
              Text(
                email,
                style: context.textStyles.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            if (phone != null && phone.isNotEmpty)
              Text(
                phone,
                style: context.textStyles.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Ativo' : 'Inativo',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: isActive ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton.icon(
                onPressed: () => _linkMember(member),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Vincular'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
      ),
    );
  }
}
