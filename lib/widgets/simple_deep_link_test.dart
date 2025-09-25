import 'package:flutter/material.dart';
import 'package:servus_app/services/deep_link_service.dart';

class SimpleDeepLinkTest extends StatelessWidget {
  const SimpleDeepLinkTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🧪 Teste de Deep Link',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _testDeepLink(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Testar Deep Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _testDeepLink(BuildContext context) async {
    
    try {
      final deepLinkService = DeepLinkService();
      
      // Simular um deep link de convite
      await deepLinkService.handleInviteLink(
        'servusapp://invite?code=ABC123&ministry=Louvor',
        context,
      );
      
    } catch (e) {
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
