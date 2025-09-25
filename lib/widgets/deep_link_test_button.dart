import 'package:flutter/material.dart';
import 'package:servus_app/services/deep_link_service.dart';

class DeepLinkTestButton extends StatelessWidget {
  const DeepLinkTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _testDeepLink(context),
      backgroundColor: Colors.blue,
      child: const Icon(Icons.link, color: Colors.white),
    );
  }

  Future<void> _testDeepLink(BuildContext context) async {
    
    final deepLinkService = DeepLinkService();
    
    try {
      await deepLinkService.handleInviteLink(
        'servusapp://invite?code=ABC123&ministry=Louvor',
        context,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao testar deep link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
