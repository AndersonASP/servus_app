import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:servus_app/services/members_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/core/network/dio_client.dart';

class MultiLinkMemberModal extends StatefulWidget {
  final MinisterioDetalhesController controller;

  const MultiLinkMemberModal({
    super.key,
    required this.controller,
  });

  @override
  State<MultiLinkMemberModal> createState() => _MultiLinkMemberModalState();
}

class _MultiLinkMemberModalState extends State<MultiLinkMemberModal> {
  final TextEditingController _searchController = TextEditingController();
  
  // Estados
  List<Member> _allMembers = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedRole = 'volunteer';
  
  // Estados do fluxo
  List<Member> _selectedMembers = []; // Múltiplos membros
  List<Map<String, dynamic>> _availableFunctions = [];
  Map<String, List<String>> _memberFunctionIds = {}; // Membro ID -> Lista de funções
  bool _isLoadingFunctions = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAllMembers();
    _loadMinistryFunctions(); // Carregar funções do ministério atual
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterMembers();
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _allMembers.where((member) {
        return member.name.toLowerCase().contains(query) ||
               member.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleMemberSelection(Member member) {
    setState(() {
      if (_selectedMembers.contains(member)) {
        _selectedMembers.remove(member);
        _memberFunctionIds.remove(member.id);
      } else {
        _selectedMembers.add(member);
        _memberFunctionIds[member.id] = [];
      }
    });
  }

  Future<void> _loadAllMembers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await MembersService.getMembers(
        filter: MemberFilter(
          page: 1,
          limit: 100, // Carregar mais membros
        ),
        context: context,
      );

      setState(() {
        _allMembers = response.members;
        _filteredMembers = response.members;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar membros: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMinistryFunctions() async {
    if (widget.controller.ministerioId.isEmpty) return;
    
    setState(() {
      _isLoadingFunctions = true;
    });

    try {
      final dio = DioClient.instance;
      final context = await TokenService.getContext();
      final token = context['token'];


      final response = await dio.get(
        '/ministries/${widget.controller.ministerioId}/functions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );


      if (response.statusCode == 200) {
        final List<dynamic> functionsData = response.data;
        setState(() {
          _availableFunctions = functionsData.map((f) => {
            'id': f['_id'] ?? f['id'],
            'name': f['name'] ?? '',
            'description': f['description'] ?? '',
          }).toList();
        });
      }
    } finally {
      setState(() {
        _isLoadingFunctions = false;
      });
    }
  }

  void _toggleFunction(String memberId, String functionId) {
    setState(() {
      final functionIds = _memberFunctionIds[memberId] ?? [];
      if (functionIds.contains(functionId)) {
        functionIds.remove(functionId);
      } else {
        functionIds.add(functionId);
      }
      _memberFunctionIds[memberId] = functionIds;
    });
    
  }

  Future<void> _linkToFunctions(String memberId, List<String> functionIds) async {
    final dio = DioClient.instance;
    final context = await TokenService.getContext();
    final token = context['token'];

    await dio.post(
      '/ministries/${widget.controller.ministerioId}/members/$memberId/functions',
      data: {
        'functionIds': functionIds,
        'status': 'pending',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> _linkMembers() async {
    if (_selectedMembers.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      
      int successCount = 0;
      int errorCount = 0;
      
      for (final member in _selectedMembers) {
        try {
          
          // PASSO 1: Vincular membro ao ministério (membership)
          final membershipSuccess = await widget.controller.vincularMembro(
            member.id, 
            _selectedRole,
          );
          
          if (!membershipSuccess) {
            throw Exception('Erro ao vincular ${member.name} ao ministério');
          }

          // PASSO 2: Vincular às funções (se houver)
          final functionIds = _memberFunctionIds[member.id] ?? [];
          if (functionIds.isNotEmpty) {
            await _linkToFunctions(member.id, functionIds);
          }
          
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      // Sucesso
      if (mounted) {
        String message;
        if (errorCount == 0) {
          message = '$successCount membro(s) vinculado(s) com sucesso!';
        } else {
          message = '$successCount membro(s) vinculado(s), $errorCount erro(s)';
        }
        
        ServusSnackQueue.addToQueue(
          context: context,
          message: message,
          type: errorCount == 0 ? ServusSnackType.success : ServusSnackType.warning,
        );
        
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ServusSnackQueue.addToQueue(
          context: context,
          message: 'Erro: $e',
          type: ServusSnackType.error,
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
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.group_add, color: context.colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vincular Múltiplos Membros',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            
            // Conteúdo
            Expanded(
              child: _buildContent(),
            ),
            
            // Botões
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllMembers,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Busca
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar membros...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de membros
        Expanded(
          child: _buildMembersList(),
        ),
        
        // Funções (se houver membros selecionados)
        if (_selectedMembers.isNotEmpty) ...[
          const Divider(),
          _buildFunctionsSection(),
        ],
      ],
    );
  }

  Widget _buildMembersList() {
    return ListView.builder(
      itemCount: _filteredMembers.length,
      itemBuilder: (context, index) {
        final member = _filteredMembers[index];
        final isSelected = _selectedMembers.contains(member);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? context.colors.primary : null,
              child: isSelected 
                ? const Icon(Icons.check, color: Colors.white)
                : Text(member.name[0].toUpperCase()),
            ),
            title: Text(member.name),
            subtitle: Text(member.email),
            trailing: Text(
              isSelected ? 'Selecionado' : 'Toque para selecionar',
              style: TextStyle(
                color: isSelected ? context.colors.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () => _toggleMemberSelection(member),
          ),
        );
      },
    );
  }

  Widget _buildFunctionsSection() {
    if (_isLoadingFunctions) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funções do Ministério',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Lista de membros selecionados com suas funções
        ..._selectedMembers.map((member) => _buildMemberFunctions(member)),
      ],
    );
  }

  Widget _buildMemberFunctions(Member member) {
    final selectedFunctionIds = _memberFunctionIds[member.id] ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (_availableFunctions.isEmpty)
              const Text('Nenhuma função disponível', style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableFunctions.map((function) {
                  final isSelected = selectedFunctionIds.contains(function['id']);
                  return GestureDetector(
                    onTap: () => _toggleFunction(member.id, function['id']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? context.colors.primary 
                            : context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? context.colors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        function['name'],
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : context.colors.onSurface,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _selectedMembers.isEmpty || _isLoading 
                ? null 
                : _linkMembers,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
            child: _isLoading 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Vincular ${_selectedMembers.length} Membro(s)'),
          ),
        ),
      ],
    );
  }
}
