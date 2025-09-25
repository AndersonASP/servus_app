import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/services/branches_service.dart';
import 'package:servus_app/services/members_service.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'create_branch_steps.dart';

class CreateBranchScreen extends StatefulWidget {
  const CreateBranchScreen({super.key});

  @override
  State<CreateBranchScreen> createState() => _CreateBranchScreenState();
}

class _CreateBranchScreenState extends State<CreateBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _complementoController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;
  
  // Opções de administrador
  String _adminOption = 'none'; // 'none', 'existing', 'new'
  Member? _selectedMember;
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  
  List<Member> _members = [];
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _complementoController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final response = await MembersService.getMembers();
      if (mounted) {
        setState(() {
          _members = response.members;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
        showLoadError(context, 'membros');
      }
    }
  }

  Future<void> _createBranch() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final branchData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'telefone': _telefoneController.text.trim().isEmpty 
            ? null 
            : _telefoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        'whatsappOficial': _whatsappController.text.trim().isEmpty 
            ? null 
            : _whatsappController.text.trim(),
        'endereco': _buildAddressData(),
        'diasCulto': [
          {
            'dia': 'domingo',
            'horarios': ['09:00', '19:30']
          }
        ],
        'eventosPadrao': [
          {
            'nome': 'Culto de Celebração',
            'dia': 'domingo',
            'horarios': ['09:00', '19:30'],
            'tipo': 'culto'
          }
        ],
        'modulosAtivos': ['voluntariado', 'eventos'],
        'corTema': '#1E40AF',
        'idioma': 'pt-BR',
        'timezone': 'America/Sao_Paulo',
      };

      // Criar filial primeiro
      final branch = await BranchesService.createBranch(branchData);

      // Se há opção de administrador, vincular depois
      if (_adminOption != 'none') {
        Map<String, dynamic> assignData = {};
        
        if (_adminOption == 'existing' && _selectedMember != null) {
          assignData['userEmail'] = _selectedMember!.email;
        } else if (_adminOption == 'new') {
          assignData['name'] = _adminNameController.text.trim();
          assignData['email'] = _adminEmailController.text.trim();
          if (_adminPasswordController.text.trim().isNotEmpty) {
            assignData['password'] = _adminPasswordController.text.trim();
          }
        }

        if (assignData.isNotEmpty) {
          await BranchesService.assignAdmin(branch.branchId, assignData);
        }
      }

      if (mounted) {
        showCreateSuccess(context, 'Filial');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showCreateError(context, 'filial');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic>? _buildAddressData() {
    final hasAddress = _cepController.text.isNotEmpty ||
        _ruaController.text.isNotEmpty ||
        _numeroController.text.isNotEmpty ||
        _bairroController.text.isNotEmpty ||
        _cidadeController.text.isNotEmpty ||
        _estadoController.text.isNotEmpty ||
        _complementoController.text.isNotEmpty;

    if (!hasAddress) return null;

    return {
      'cep': _cepController.text.trim().isEmpty ? null : _cepController.text.trim(),
      'rua': _ruaController.text.trim().isEmpty ? null : _ruaController.text.trim(),
      'numero': _numeroController.text.trim().isEmpty ? null : _numeroController.text.trim(),
      'bairro': _bairroController.text.trim().isEmpty ? null : _bairroController.text.trim(),
      'cidade': _cidadeController.text.trim().isEmpty ? null : _cidadeController.text.trim(),
      'estado': _estadoController.text.trim().isEmpty ? null : _estadoController.text.trim(),
      'complemento': _complementoController.text.trim().isEmpty ? null : _complementoController.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Filial'),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Indicador de steps
            _buildStepIndicator(),
            
            // Conteúdo do step atual
            Expanded(
              child: _buildStepContent(),
            ),
            
            // Botões de navegação
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepItem(0, 'Informações', Icons.info_outline),
          _buildStepConnector(),
          _buildStepItem(1, 'Contato', Icons.contact_phone),
          _buildStepConnector(),
          _buildStepItem(2, 'Endereço', Icons.location_on),
          _buildStepConnector(),
          _buildStepItem(3, 'Administrador', Icons.admin_panel_settings),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String title, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive || isCompleted 
                  ? context.colors.primary 
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive || isCompleted 
                  ? Colors.white 
                  : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive || isCompleted 
                  ? context.colors.primary 
                  : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      height: 2,
      width: 20,
      color: _currentStep > 0 ? context.colors.primary : Colors.grey.shade300,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return CreateBranchSteps.buildBasicInfoStep(
          nameController: _nameController,
          descriptionController: _descriptionController,
          context: context,
        );
      case 1:
        return CreateBranchSteps.buildContactStep(
          telefoneController: _telefoneController,
          emailController: _emailController,
          whatsappController: _whatsappController,
          context: context,
        );
      case 2:
        return CreateBranchSteps.buildAddressStep(
          cepController: _cepController,
          ruaController: _ruaController,
          numeroController: _numeroController,
          bairroController: _bairroController,
          cidadeController: _cidadeController,
          estadoController: _estadoController,
          complementoController: _complementoController,
          context: context,
        );
      case 3:
        return CreateBranchSteps.buildAdminStep(
          adminOption: _adminOption,
          onAdminOptionChanged: (value) {
            setState(() {
              _adminOption = value;
            });
          },
          selectedMember: _selectedMember,
          onMemberSelected: (member) {
            setState(() {
              _selectedMember = member;
            });
          },
          members: _members,
          isLoadingMembers: _isLoadingMembers,
          adminNameController: _adminNameController,
          adminEmailController: _adminEmailController,
          adminPasswordController: _adminPasswordController,
          context: context,
        );
      default:
        return CreateBranchSteps.buildBasicInfoStep(
          nameController: _nameController,
          descriptionController: _descriptionController,
          context: context,
        );
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                child: const Text('Anterior'),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextOrCreate,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == 3 ? 'Criar Filial' : 'Próximo'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextOrCreate() {
    if (_currentStep == 3) {
      _createBranch();
    } else {
      // Validar campos do step atual
      bool isValid = true;
      
      switch (_currentStep) {
        case 0:
          if (_nameController.text.trim().isEmpty) {
            isValid = false;
            showValidationError(context, 'Nome da filial é obrigatório');
          }
          break;
        case 1:
          // Validação opcional para contato
          break;
        case 2:
          // Validação opcional para endereço
          break;
        case 3:
          if (_adminOption == 'existing' && _selectedMember == null) {
            isValid = false;
            showValidationError(context, 'Selecione um membro para ser administrador');
          } else if (_adminOption == 'new') {
            if (_adminNameController.text.trim().isEmpty ||
                _adminEmailController.text.trim().isEmpty) {
              isValid = false;
              showValidationError(context, 'Nome e email do administrador são obrigatórios');
            }
          }
          break;
      }
      
      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }
}
