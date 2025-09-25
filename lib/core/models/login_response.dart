class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserData user;
  final TenantData? tenant;
  final List<BranchData>? branches;
  final List<MembershipData>? memberships;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    this.tenant,
    this.branches,
    this.memberships,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: json['expires_in'] ?? 3600,
      user: UserData.fromJson(json['user'] ?? {}),
      tenant: json['tenant'] != null ? TenantData.fromJson(json['tenant']) : null,
      branches: json['branches'] != null 
          ? List<BranchData>.from(json['branches'].map((x) => BranchData.fromJson(x)))
          : null,
      memberships: json['memberships'] != null 
          ? List<MembershipData>.from(json['memberships'].map((x) => MembershipData.fromJson(x)))
          : null,
    );
  }
}

class UserData {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? picture;

  UserData({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.picture,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      picture: json['picture'],
    );
  }
}

class TenantData {
  final String id;
  final String tenantId;
  final String name;
  final String? logoUrl;

  TenantData({
    required this.id,
    required this.tenantId,
    required this.name,
    this.logoUrl,
  });

  factory TenantData.fromJson(Map<String, dynamic> json) {
    return TenantData(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'],
    );
  }
}

class BranchData {
  final String id;
  final String branchId;
  final String name;

  BranchData({
    required this.id,
    required this.branchId,
    required this.name,
  });

  factory BranchData.fromJson(Map<String, dynamic> json) {
    return BranchData(
      id: json['id'] ?? '',
      branchId: json['branchId'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class MembershipData {
  final String id;
  final String role;
  final List<String> permissions;
  final bool isActive;
  final BranchData? branch;
  final MinistryData? ministry;

  MembershipData({
    required this.id,
    required this.role,
    required this.permissions,
    required this.isActive,
    this.branch,
    this.ministry,
  });

  factory MembershipData.fromJson(Map<String, dynamic> json) {
    return MembershipData(
      id: json['id'] ?? '',
      role: json['role'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      isActive: json['isActive'] ?? true,
      branch: json['branch'] != null ? BranchData.fromJson(json['branch']) : null,
      ministry: json['ministry'] != null ? MinistryData.fromJson(json['ministry']) : null,
    );
  }
}

class MinistryData {
  final String id;
  final String name;

  MinistryData({
    required this.id,
    required this.name,
  });

  factory MinistryData.fromJson(Map<String, dynamic> json) {
    return MinistryData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
} 