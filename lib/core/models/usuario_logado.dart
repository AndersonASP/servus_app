import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/models/ministerio.dart';

class UsuarioLogado {
  final String nome;
  final String email;
  final String? tenantName;
  final String? branchName;
  final UserRole role;
  final List<Ministerio> ministerios;
  final String? tenantId;
  final String? branchId;
  final String? picture;
  final String? primaryMinistryId; // 🆕 ID do ministério principal
  final String? primaryMinistryName; // 🆕 Nome do ministério principal

  UsuarioLogado({
    required this.nome,
    required this.email,
    this.tenantName,
    this.branchName,
    required this.role,
    this.tenantId,
    this.branchId,
    this.picture,
    this.ministerios = const [],
    this.primaryMinistryId,
    this.primaryMinistryName,
  });

  bool get isAdmin => role == UserRole.servus_admin || role == UserRole.tenant_admin || role == UserRole.branch_admin;
  bool get isLider => role == UserRole.leader;
  bool get isVoluntario => role == UserRole.volunteer ;

  UsuarioLogado copyWith({
    String? nome,
    String? email,
    String? tenantName,
    String? branchName,
    UserRole? papeis,
    UserRole? papelSelecionado,
    List<Ministerio>? ministerios,
    String? tenantId,
    String? branchId,
    String? picture,
    String? primaryMinistryId,
    String? primaryMinistryName,
  }) {
    return UsuarioLogado(
      nome: nome ?? this.nome,
      email: email ?? this.email,
      tenantName: tenantName ?? this.tenantName,
      branchName: branchName ?? this.branchName,
      role: papeis ?? role,
      ministerios: ministerios ?? this.ministerios,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      picture: picture ?? this.picture,
      primaryMinistryId: primaryMinistryId ?? this.primaryMinistryId,
      primaryMinistryName: primaryMinistryName ?? this.primaryMinistryName,
    );
  }
}