import 'package:flutter/material.dart';
import 'package:servus_app/core/models/branch.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class BranchDetailsScreen extends StatelessWidget {
  final Branch branch;

  const BranchDetailsScreen({
    super.key,
    required this.branch,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(branch.name),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implementar edição
              showInfo(context, 'Funcionalidade de edição em desenvolvimento');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status e informações básicas
            _buildStatusCard(context),
            
            const SizedBox(height: 16),
            
            // Informações de contato
            _buildContactCard(context),
            
            const SizedBox(height: 16),
            
            // Endereço
            if (branch.endereco != null) ...[
              _buildAddressCard(context),
              const SizedBox(height: 16),
            ],
            
            // Dias de culto
            if (branch.diasCulto != null && branch.diasCulto!.isNotEmpty) ...[
              _buildCultoDaysCard(context),
              const SizedBox(height: 16),
            ],
            
            // Eventos padrão
            if (branch.eventosPadrao != null && branch.eventosPadrao!.isNotEmpty) ...[
              _buildEventosCard(context),
              const SizedBox(height: 16),
            ],
            
            // Módulos ativos
            if (branch.modulosAtivos != null && branch.modulosAtivos!.isNotEmpty) ...[
              _buildModulosCard(context),
              const SizedBox(height: 16),
            ],
            
            // Informações técnicas
            _buildTechnicalInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: context.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status da Filial',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  branch.isActive ? Icons.check_circle : Icons.cancel,
                  color: branch.isActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  branch.isActive ? 'Ativo' : 'Inativo',
                  style: TextStyle(
                    color: branch.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (branch.description != null) ...[
              const SizedBox(height: 8),
              Text(
                branch.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_phone,
                  color: context.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contato',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (branch.telefone != null) ...[
              _buildInfoRow(Icons.phone, 'Telefone', branch.telefone!),
              const SizedBox(height: 8),
            ],
            if (branch.email != null) ...[
              _buildInfoRow(Icons.email, 'Email', branch.email!),
              const SizedBox(height: 8),
            ],
            if (branch.whatsappOficial != null) ...[
              _buildInfoRow(Icons.phone, 'WhatsApp', branch.whatsappOficial!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    final endereco = branch.endereco!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: context.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Endereço',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (endereco.fullAddress.isNotEmpty) ...[
              Text(
                endereco.fullAddress,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              if (endereco.rua != null) _buildInfoRow(Icons.streetview, 'Rua', endereco.rua!),
              if (endereco.numero != null) _buildInfoRow(Icons.numbers, 'Número', endereco.numero!),
              if (endereco.bairro != null) _buildInfoRow(Icons.location_city, 'Bairro', endereco.bairro!),
              if (endereco.cidade != null) _buildInfoRow(Icons.location_city, 'Cidade', endereco.cidade!),
              if (endereco.estado != null) _buildInfoRow(Icons.flag, 'Estado', endereco.estado!),
              if (endereco.cep != null) _buildInfoRow(Icons.local_post_office, 'CEP', endereco.cep!),
              if (endereco.complemento != null) _buildInfoRow(Icons.info, 'Complemento', endereco.complemento!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCultoDaysCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: context.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dias de Culto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...branch.diasCulto!.map((dia) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDay(dia.dia),
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dia.horarios.join(', '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEventosCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: context.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Eventos Padrão',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...branch.eventosPadrao!.map((evento) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.nome,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_formatDay(evento.dia)} - ${evento.horarios.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildModulosCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.apps,
                  color: context.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Módulos Ativos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: branch.modulosAtivos!.map((modulo) => Chip(
                label: Text(_formatModulo(modulo)),
                backgroundColor: context.colors.primary.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: context.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informações Técnicas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.fingerprint, 'ID da Filial', branch.branchId),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.language, 'Idioma', branch.idioma ?? 'pt-BR'),
            if (branch.timezone != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, 'Fuso Horário', branch.timezone!),
            ],
            if (branch.corTema != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.palette, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Cor do Tema: ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(int.parse(branch.corTema!.replaceFirst('#', '0xff'))),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Criado por', branch.createdBy ?? 'Sistema'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Criado em', _formatDate(branch.createdAt)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.update, 'Atualizado em', _formatDate(branch.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatDay(String day) {
    switch (day.toLowerCase()) {
      case 'domingo': return 'Dom';
      case 'segunda': return 'Seg';
      case 'terca': return 'Ter';
      case 'quarta': return 'Qua';
      case 'quinta': return 'Qui';
      case 'sexta': return 'Sex';
      case 'sabado': return 'Sáb';
      default: return day;
    }
  }

  String _formatModulo(String modulo) {
    switch (modulo.toLowerCase()) {
      case 'voluntariado': return 'Voluntariado';
      case 'eventos': return 'Eventos';
      case 'financeiro': return 'Financeiro';
      case 'membros': return 'Membros';
      case 'ministerios': return 'Ministérios';
      default: return modulo;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} às '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
}
