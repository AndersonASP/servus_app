import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/volunteers/controllers/volunteers_controller.dart';
import 'package:servus_app/state/auth_state.dart';

class VolunteersListScreen extends StatefulWidget {
  const VolunteersListScreen({super.key});

  @override
  State<VolunteersListScreen> createState() => _VolunteersListScreenState();
}

class _VolunteersListScreenState extends State<VolunteersListScreen> {
  late final VolunteersController controller;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthState>(context, listen: false);
    controller = VolunteersController(auth: auth);
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<VolunteersController>(
        builder: (context, controller, _) {
          final filteredVolunteers = _getFilteredVolunteers(controller.volunteers);

          return Scaffold(
            backgroundColor: context.theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Lista de Voluntários'),
              backgroundColor: Colors.transparent,
              foregroundColor: context.colors.onSurface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: context.colors.onSurface,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: context.colors.onSurface,
                  ),
                  onPressed: () => controller.refreshVolunteers(),
                ),
              ],
            ),
            body: controller.isLoading && !controller.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Barra de pesquisa e filtros
                      _buildSearchAndFilters(context),
                      
                      // Lista de voluntários
                      Expanded(
                        child: filteredVolunteers.isEmpty
                            ? _buildEmptyState(context)
                            : RefreshIndicator(
                                onRefresh: () => controller.refreshVolunteers(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredVolunteers.length,
                                  itemBuilder: (context, index) {
                                    final volunteer = filteredVolunteers[index];
                                    return _buildVolunteerCard(context, volunteer);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Barra de pesquisa
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Pesquisar voluntários...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.colors.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.colors.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'all', 'Todos'),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'approved', 'Aprovados'),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'pending', 'Pendentes'),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'rejected', 'Rejeitados'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String value, String label) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: context.colors.primary.withOpacity(0.2),
      checkmarkColor: context.colors.primary,
      labelStyle: TextStyle(
        color: isSelected ? context.colors.primary : context.colors.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: context.colors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum voluntário encontrado',
              style: context.textStyles.headlineSmall?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Nenhum voluntário corresponde à sua pesquisa'
                  : 'Os voluntários aparecerão aqui quando se registrarem',
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpar pesquisa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerCard(BuildContext context, Map<String, dynamic> volunteer) {
    final status = volunteer['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com nome e status
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: context.colors.primary.withOpacity(0.1),
                child: Text(
                  (volunteer['name'] ?? 'V')[0].toUpperCase(),
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer['name'] ?? 'Nome não informado',
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      volunteer['ministry']?['name'] ?? 'Ministério não informado',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  statusText,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Informações de contato
          _buildInfoRow(context, Icons.email, volunteer['email'] ?? 'Não informado'),
          const SizedBox(height: 4),
          _buildInfoRow(context, Icons.phone, volunteer['phone'] ?? 'Não informado'),
          
          // Funções selecionadas
          if (volunteer['functions'] != null && (volunteer['functions'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Funções:',
              style: context.textStyles.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (volunteer['functions'] as List).map((function) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.colors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    function.toString(),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Data de aprovação ou submissão
          Text(
            status == 'approved' 
                ? 'Aprovado em: ${_formatDate(volunteer['approvedAt'])}'
                : 'Submetido em: ${_formatDate(volunteer['createdAt'])}',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: context.colors.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredVolunteers(List<Map<String, dynamic>> volunteers) {
    var filtered = volunteers;

    // Aplicar filtro de status
    if (_selectedFilter != 'all') {
      filtered = filtered.where((volunteer) {
        final status = volunteer['status'] ?? 'pending';
        return status == _selectedFilter;
      }).toList();
    }

    // Aplicar pesquisa
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((volunteer) {
        final name = (volunteer['name'] ?? '').toLowerCase();
        final email = (volunteer['email'] ?? '').toLowerCase();
        final ministry = (volunteer['ministry']?['name'] ?? '').toLowerCase();
        
        return name.contains(_searchQuery) ||
               email.contains(_searchQuery) ||
               ministry.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'rejected':
        return 'Rejeitado';
      case 'pending':
        return 'Pendente';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Data não informada';
    
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }
}
