import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/member.dart';

class CreateBranchSteps {
  static Widget buildBasicInfoStep({
    required TextEditingController nameController,
    required TextEditingController descriptionController,
    required BuildContext context,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações Básicas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preencha as informações básicas da filial',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da Filial *',
              border: OutlineInputBorder(),
              hintText: 'Ex: Filial Centro',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome da filial é obrigatório';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              border: OutlineInputBorder(),
              hintText: 'Descrição da filial (opcional)',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  static Widget buildContactStep({
    required TextEditingController telefoneController,
    required TextEditingController emailController,
    required TextEditingController whatsappController,
    required BuildContext context,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contato',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informações de contato da filial',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: telefoneController,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              border: OutlineInputBorder(),
              hintText: '(11) 99999-9999',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              hintText: 'contato@filial.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email inválido';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: whatsappController,
            decoration: const InputDecoration(
              labelText: 'WhatsApp Oficial',
              border: OutlineInputBorder(),
              hintText: '(11) 99999-9999',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildAddressStep({
    required TextEditingController cepController,
    required TextEditingController ruaController,
    required TextEditingController numeroController,
    required TextEditingController bairroController,
    required TextEditingController cidadeController,
    required TextEditingController estadoController,
    required TextEditingController complementoController,
    required BuildContext context,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Endereço',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Localização da filial',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: cepController,
                  decoration: const InputDecoration(
                    labelText: 'CEP',
                    border: OutlineInputBorder(),
                    hintText: '12345-678',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: ruaController,
                  decoration: const InputDecoration(
                    labelText: 'Rua',
                    border: OutlineInputBorder(),
                    hintText: 'Rua das Flores',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Número',
                    border: OutlineInputBorder(),
                    hintText: '123',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: bairroController,
                  decoration: const InputDecoration(
                    labelText: 'Bairro',
                    border: OutlineInputBorder(),
                    hintText: 'Centro',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: cidadeController,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    border: OutlineInputBorder(),
                    hintText: 'São Paulo',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: estadoController,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    hintText: 'SP',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: complementoController,
            decoration: const InputDecoration(
              labelText: 'Complemento',
              border: OutlineInputBorder(),
              hintText: 'Sala 101, 2º andar',
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildAdminStep({
    required String adminOption,
    required Function(String) onAdminOptionChanged,
    required Member? selectedMember,
    required Function(Member?) onMemberSelected,
    required List<Member> members,
    required bool isLoadingMembers,
    required TextEditingController adminNameController,
    required TextEditingController adminEmailController,
    required TextEditingController adminPasswordController,
    required BuildContext context,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administrador',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure o administrador da filial',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Opções de administrador
          _buildAdminOption(
            'none', 
            'Não criar administrador', 
            'A filial será criada sem administrador específico',
            adminOption,
            onAdminOptionChanged,
            context,
          ),
          
          const SizedBox(height: 16),
          
          _buildAdminOption(
            'existing', 
            'Vincular membro existente', 
            'Selecionar um membro já cadastrado como administrador',
            adminOption,
            onAdminOptionChanged,
            context,
          ),
          
          const SizedBox(height: 16),
          
          _buildAdminOption(
            'new', 
            'Criar novo administrador', 
            'Criar um novo usuário como administrador da filial',
            adminOption,
            onAdminOptionChanged,
            context,
          ),
          
          // Conteúdo condicional baseado na opção selecionada
          if (adminOption == 'existing') ...[
            const SizedBox(height: 24),
            _buildExistingMemberSelector(
              selectedMember,
              onMemberSelected,
              members,
              isLoadingMembers,
              context,
            ),
          ] else if (adminOption == 'new') ...[
            const SizedBox(height: 24),
            _buildNewAdminForm(
              adminNameController,
              adminEmailController,
              adminPasswordController,
              adminOption,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildAdminOption(
    String value, 
    String title, 
    String subtitle,
    String currentOption,
    Function(String) onChanged,
    BuildContext context,
  ) {
    final isSelected = currentOption == value;
    
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? context.colors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? context.colors.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: currentOption,
              onChanged: (newValue) => onChanged(newValue!),
              activeColor: context.colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? context.colors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildExistingMemberSelector(
    Member? selectedMember,
    Function(Member?) onMemberSelected,
    List<Member> members,
    bool isLoadingMembers,
    BuildContext context,
  ) {
    if (isLoadingMembers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Nenhum membro encontrado'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecionar Membro:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...(members.map((member) => _buildMemberOption(
          member,
          selectedMember,
          onMemberSelected,
          context,
        ))),
      ],
    );
  }

  static Widget _buildMemberOption(
    Member member,
    Member? selectedMember,
    Function(Member?) onMemberSelected,
    BuildContext context,
  ) {
    final isSelected = selectedMember?.id == member.id;
    
    return InkWell(
      onTap: () => onMemberSelected(member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? context.colors.primary : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? context.colors.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.colors.primary,
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
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
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    member.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.colors.primary,
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildNewAdminForm(
    TextEditingController adminNameController,
    TextEditingController adminEmailController,
    TextEditingController adminPasswordController,
    String adminOption,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados do Novo Administrador:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: adminNameController,
          decoration: const InputDecoration(
            labelText: 'Nome do Administrador *',
            border: OutlineInputBorder(),
            hintText: 'João Silva',
          ),
          validator: adminOption == 'new' ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome do administrador é obrigatório';
            }
            return null;
          } : null,
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: adminEmailController,
          decoration: const InputDecoration(
            labelText: 'Email do Administrador *',
            border: OutlineInputBorder(),
            hintText: 'joao@igreja.com',
          ),
          keyboardType: TextInputType.emailAddress,
          validator: adminOption == 'new' ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email do administrador é obrigatório';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email inválido';
            }
            return null;
          } : null,
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: adminPasswordController,
          decoration: const InputDecoration(
            labelText: 'Senha do Administrador',
            border: OutlineInputBorder(),
            hintText: 'Deixe em branco para gerar automaticamente',
            helperText: 'Se não informada, uma senha será gerada e enviada por email',
          ),
          obscureText: true,
        ),
      ],
    );
  }
}
