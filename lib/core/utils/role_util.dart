import 'package:servus_app/core/enums/user_role.dart';

UserRole mapRoleToEnum(String? role) {
  switch (role) {
    case 'superadmin':
    case 'admin':
      return UserRole.admin;
    case 'leader':
      return UserRole.leader; // (verifique se "leaeder" está correto ou é um typo de "leader")
    default:
      return UserRole.volunteer;
  }
}

/// Converte de enum UserRole para string
String mapRoleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.leader:
      return 'leader';
    case UserRole.volunteer:
      return 'volunteer';
    case UserRole.superadmin:
      return 'superadmin';
  }
}