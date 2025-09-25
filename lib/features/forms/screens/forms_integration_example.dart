import 'package:flutter/material.dart';
import 'package:servus_app/services/auth_integration_service.dart';

/// Exemplo de como integrar o sistema de formulários com o estado de autenticação real
class FormsIntegrationExample extends StatefulWidget {
  const FormsIntegrationExample({super.key});

  @override
  State<FormsIntegrationExample> createState() => _FormsIntegrationExampleState();
}

class _FormsIntegrationExampleState extends State<FormsIntegrationExample> {
  final AuthIntegrationService _authIntegration = AuthIntegrationService.instance;

  @override
  void initState() {
    super.initState();
    _integrateWithAuth();
  }

  void _integrateWithAuth() {
    // TODO: Substituir por acesso real ao AuthState
    // Exemplo de como seria a integração:
    
    // final authState = Provider.of<AuthState>(context, listen: false);
    // _authIntegration.integrateWithAuthState(authState);
    
    // Por enquanto, simulando um estado de autenticação
    _simulateAuthState();
  }

  void _simulateAuthState() {
    // Simulação de um usuário autenticado
    final mockUser = MockUser(
      id: 'user123',
      email: 'lider@igreja.com',
      name: 'João Silva',
    );
    
    final mockAuthState = MockAuthState(
      isAuthenticated: true,
      user: mockUser,
    );
    
    _authIntegration.integrateWithAuthState(mockAuthState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integração de Autenticação'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status da Integração',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _authIntegration.hasValidContext 
                              ? Icons.check_circle 
                              : Icons.error,
                          color: _authIntegration.hasValidContext 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _authIntegration.hasValidContext 
                              ? 'Contexto de autenticação disponível'
                              : 'Contexto de autenticação não disponível',
                          style: TextStyle(
                            color: _authIntegration.hasValidContext 
                                ? Colors.green 
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _simulateAuthState,
                      child: const Text('Simular Autenticação'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como Integrar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Para integrar com o estado de autenticação real:\n\n'
                      '1. Importe AuthIntegrationService\n'
                      '2. Chame integrateWithAuthState(authState) no initState\n'
                      '3. Os serviços automaticamente usarão o contexto\n\n'
                      'Exemplo:\n'
                      '```dart\n'
                      'final authState = Provider.of<AuthState>(context);\n'
                      'AuthIntegrationService.instance\n'
                      '    .integrateWithAuthState(authState);\n'
                      '```',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Classes mock para demonstração
class MockUser {
  final String id;
  final String email;
  final String name;

  MockUser({
    required this.id,
    required this.email,
    required this.name,
  });
}

class MockAuthState {
  final bool isAuthenticated;
  final MockUser? user;

  MockAuthState({
    required this.isAuthenticated,
    this.user,
  });
}
