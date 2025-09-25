import 'package:flutter/material.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';
import 'package:servus_app/features/ministries/services/member_function_service.dart';
import 'package:servus_app/features/ministries/models/member_function.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class MemberDetailsScreen extends StatefulWidget {
  final Member member;

  const MemberDetailsScreen({
    super.key,
    required this.member,
  });

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  final MemberFunctionService _memberFunctionService = MemberFunctionService();
  List<MemberFunction> _approvedFunctions = [];
  bool _isLoadingFunctions = true;

  @override
  void initState() {
    super.initState();
    _loadApprovedFunctions();
  }

  Future<void> _loadApprovedFunctions() async {
    if (widget.member.id.isEmpty) {
      setState(() {
        _isLoadingFunctions = false;
      });
      return;
    }

    try {
      final functions = await _memberFunctionService.getApprovedFunctionsForUser(
        userId: widget.member.id,
      );
      setState(() {
        _approvedFunctions = functions;
        _isLoadingFunctions = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar funções aprovadas: $e');
      setState(() {
        _isLoadingFunctions = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: const Text('Detalhes do Membro'),
      ),
      body: FabSafeScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildBasicInfo(),
            const SizedBox(height: 24),
            _buildMemberships(),
            const SizedBox(height: 24),
            _buildApprovedFunctions(),
            const SizedBox(height: 24),
            // _buildAdditionalInfo(),
            if (widget.member.address != null) ...[
              const SizedBox(height: 24),
              _buildAddress(),
            ],
          ],
        ),
      ),
      // Botão flutuante de editar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar edição
          showInfo(context, 'Funcionalidade de edição em desenvolvimento');
        },
        icon: const Icon(Icons.edit),
        label: const Text('Editar Membro'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: widget.member.isActive ? context.colors.primary : Colors.grey,
              child: widget.member.picture != null
                  ? ClipOval(
                      child: Image.network(
                        widget.member.picture!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            widget.member.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      widget.member.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.member.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.member.email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.member.isActive ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.member.isActive ? 'Ativo' : 'Inativo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.member.profileCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Perfil Completo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Básicas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.member.phone != null) _buildInfoRow('Telefone', widget.member.phone!),
            if (widget.member.birthDate != null) _buildInfoRow('Data de Nascimento', _formatBirthDate(widget.member.birthDate!)),
            _buildInfoRow('Role Global', _normalizeRole(widget.member.role)),
            _buildInfoRow('Membro desde', _formatDate(widget.member.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberships() {
    final activeMemberships = widget.member.memberships.where((m) => m.isActive).toList();
    if (activeMemberships.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vínculos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum vínculo encontrado',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vínculos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...activeMemberships.map((membership) => _buildMembershipCard(membership)),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard(MembershipResponse membership) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: membership.isActive ? context.colors.primary : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _normalizeRole(membership.role),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!membership.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Inativo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (membership.branch != null)
              Text('Filial: ${membership.branch!.name}'),
            if (membership.ministry != null)
              Text('Ministério: ${membership.ministry!.name}'),
            const SizedBox(height: 4),
            Text(
              'Vínculo desde: ${_formatDate(membership.createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedFunctions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: context.colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Funções Aprovadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingFunctions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_approvedFunctions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: context.colors.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nenhuma função aprovada encontrada',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _approvedFunctions.map((memberFunction) => _buildFunctionCard(memberFunction)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionCard(MemberFunction memberFunction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(memberFunction.status),
                color: _getStatusColor(memberFunction.status),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  memberFunction.function?.name ?? 'Função',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(memberFunction.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  memberFunction.statusDisplayName,
                  style: TextStyle(
                    color: context.colors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (memberFunction.function?.description != null) ...[
            const SizedBox(height: 8),
            Text(
              memberFunction.function!.description!,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.church,
                size: 16,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Ministério: ${memberFunction.ministry?.name ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (memberFunction.approvedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Aprovada em: ${_formatDate(memberFunction.approvedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildAddress() {
    final address = widget.member.address!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endereço',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (address.cep != null) _buildInfoRow('CEP', address.cep!),
            if (address.rua != null) _buildInfoRow('Rua', address.rua!),
            if (address.numero != null) _buildInfoRow('Número', address.numero!),
            if (address.bairro != null) _buildInfoRow('Bairro', address.bairro!),
            if (address.cidade != null) _buildInfoRow('Cidade', address.cidade!),
            if (address.estado != null) _buildInfoRow('Estado', address.estado!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatBirthDate(String birthDate) {
    try {
      // Tenta converter string para DateTime
      final date = DateTime.parse(birthDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      // Se não conseguir converter, retorna a string original
      return birthDate;
    }
  }

  Color _getStatusColor(MemberFunctionStatus status) {
    switch (status) {
      case MemberFunctionStatus.approved:
        return ServusColors.success;
      case MemberFunctionStatus.pending:
        return Colors.orange;
      case MemberFunctionStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(MemberFunctionStatus status) {
    switch (status) {
      case MemberFunctionStatus.approved:
        return Icons.check_circle;
      case MemberFunctionStatus.pending:
        return Icons.pending;
      case MemberFunctionStatus.rejected:
        return Icons.cancel;
    }
  }
}
