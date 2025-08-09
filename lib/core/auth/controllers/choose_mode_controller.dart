// choose_mode_controller.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/state/auth_state.dart';

class ChooseModeController {
  final AuthState auth;

  ChooseModeController({required this.auth});

  bool get isAdmin => auth.usuario?.isAdmin ?? false;
  bool get isLider => auth.usuario?.isLider ?? false;
  bool get isVoluntario => auth.usuario?.isVoluntario ?? false;

  void selecionarPapel(BuildContext context, UserRole papel) {
    auth.selecionarPapel(papel);

    switch (papel) {
      case UserRole.superadmin:
      case UserRole.admin:
      case UserRole.leader:
        context.go('/leader/dashboard');
        break;
      case UserRole.volunteer:
        context.go('/volunteer/dashboard');
        break;
    }
  }
}