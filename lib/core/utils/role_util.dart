import 'package:servus_app/core/enums/user_role.dart';

UserRole mapRoleToEnum(String? role) {
  
  switch (role) {
    case 'servus_admin':
      return UserRole.servus_admin;
    case 'tenant_admin':
      return UserRole.tenant_admin;
    case 'branch_admin':
      return UserRole.branch_admin;
    case 'leader':
      return UserRole.leader;
    case 'volunteer':
      return UserRole.volunteer;
    default:
      return UserRole.volunteer;
  }
}

/// Converte de enum UserRole para string
String mapRoleToString(UserRole role) {
  switch (role) {
    case UserRole.servus_admin:
      return 'servus_admin';
    case UserRole.tenant_admin:
      return 'tenant_admin';
    case UserRole.branch_admin:
      return 'branch_admin';
    case UserRole.leader:
      return 'leader';
    case UserRole.volunteer:
      return 'volunteer';
  }
}