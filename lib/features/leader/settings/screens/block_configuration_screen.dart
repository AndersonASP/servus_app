import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/models/block_configuration.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/services/block_configuration_service.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

/// Tela para configurar limites de bloqueio por ministério
class BlockConfigurationScreen extends StatefulWidget {
  const BlockConfigurationScreen({super.key});

  @override
  State<BlockConfigurationScreen> createState() => _BlockConfigurationScreenState();
}

class _BlockConfigurationScreenState extends State<BlockConfigurationScreen> {
  List<BlockConfiguration> _configurations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
  }

  Future<void> _loadConfigurations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      final usuario = authState.usuario;
      
      if (usuario?.tenantId != null) {
        final configurations = await BlockConfigurationService.getAllConfigurations(
          tenantId: usuario!.tenantId!,
        );
        
        setState(() {
          _configurations = configurations;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Tenant ID não encontrado';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar configurações: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateConfiguration(BlockConfiguration config, int newLimit) async {
    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      final usuario = authState.usuario;
      final userId = await TokenService.getUserId();
      
      if (usuario?.tenantId != null && userId != null) {
        final updatedConfig = config.copyWith(
          maxBlockedDays: newLimit,
          updatedAt: DateTime.now(),
          updatedBy: userId,
        );

        final success = await BlockConfigurationService.saveConfiguration(
          tenantId: usuario!.tenantId!,
          configuration: updatedConfig,
        );

        if (success) {
          setState(() {
            final index = _configurations.indexWhere((c) => c.ministryId == config.ministryId);
            if (index != -1) {
              _configurations[index] = updatedConfig;
            }
          });
          
          if (mounted) {
            showSuccess(
              context,
              'Limite atualizado para ${config.ministryName}',
              title: 'Configuração salva',
            );
          }
        } else {
          if (mounted) {
            showError(
              context,
              'Erro ao salvar configuração',
              title: 'Erro',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showError(
          context,
          'Erro ao atualizar configuração: $e',
          title: 'Erro',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Bloqueio'),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConfigurations,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_configurations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 64,
              color: context.colors.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma configuração encontrada',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As configurações serão criadas automaticamente quando necessário',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _configurations.length,
      itemBuilder: (context, index) {
        final config = _configurations[index];
        return _buildConfigurationCard(config);
      },
    );
  }

  Widget _buildConfigurationCard(BlockConfiguration config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: context.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    config.ministryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: config.isActive 
                        ? context.colors.primary.withValues(alpha: 0.1)
                        : context.colors.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    config.isActive ? 'Ativo' : 'Inativo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: config.isActive 
                          ? context.colors.primary
                          : context.colors.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Limite máximo de dias bloqueados:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: config.maxBlockedDays.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: context.colors.primary,
                    inactiveColor: context.colors.primary.withValues(alpha: 0.3),
                    onChanged: config.isActive ? (value) {
                      _updateConfiguration(config, value.round());
                    } : null,
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${config.maxBlockedDays}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Última atualização: ${_formatDate(config.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
