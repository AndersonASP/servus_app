import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/features/invite/screens/invite_code_screen.dart';
import 'package:servus_app/features/invite/screens/invite_register_screen.dart';
import 'package:servus_app/features/invite/screens/invite_success_screen.dart';

final List<GoRoute> inviteRoutes = [
  // Tela de código de convite
  GoRoute(
    path: '/invite/code',
    builder: (context, state) => const InviteCodeScreen(),
  ),
  
  // Tela de cadastro com código de convite
  GoRoute(
    path: '/invite/register',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      if (extra == null) {
        // Se não tem dados, redireciona para código
        return const InviteCodeScreen();
      }
      
      return InviteRegisterScreen(
        code: extra['code'] as String,
        ministryName: extra['ministryName'] as String,
        ministryId: extra['ministryId'] as String,
      );
    },
  ),
  
  // Tela de sucesso após cadastro
  GoRoute(
    path: '/invite/success',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      if (extra == null) {
        // Se não tem dados, redireciona para login
        return const Scaffold(
          body: Center(
            child: Text('Erro: dados não encontrados'),
          ),
        );
      }
      
      return InviteSuccessScreen(
        ministryName: extra['ministryName'] as String,
        userName: extra['userName'] as String,
      );
    },
  ),
];
