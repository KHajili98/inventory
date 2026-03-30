// ── User Role ─────────────────────────────────────────────────────────────────

enum UserRole {
  warehouseStaff,
  supervisor,
  accountant,
  salesRep,
  unknown;

  static UserRole fromString(String value) {
    switch (value) {
      case 'warehouse_staff':
        return UserRole.warehouseStaff;
      case 'supervisor':
        return UserRole.supervisor;
      case 'accountant':
        return UserRole.accountant;
      case 'sales_rep':
        return UserRole.salesRep;
      default:
        return UserRole.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.warehouseStaff:
        return 'Warehouse Staff';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.accountant:
        return 'Accountant';
      case UserRole.salesRep:
        return 'Sales Representative';
      case UserRole.unknown:
        return 'Unknown';
    }
  }

  String get value {
    switch (this) {
      case UserRole.warehouseStaff:
        return 'warehouse_staff';
      case UserRole.supervisor:
        return 'supervisor';
      case UserRole.accountant:
        return 'accountant';
      case UserRole.salesRep:
        return 'sales_rep';
      case UserRole.unknown:
        return 'unknown';
    }
  }
}

// ── Auth User ─────────────────────────────────────────────────────────────────

class AuthUser {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool isActive;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    role: UserRole.fromString(json['role'] as String),
    isActive: json['is_active'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'phone': phone,
    'first_name': firstName,
    'last_name': lastName,
    'role': role.value,
    'is_active': isActive,
  };
}

// ── Login Response ────────────────────────────────────────────────────────────

class LoginResponse {
  final AuthUser user;
  final String access;
  final String refresh;

  const LoginResponse({required this.user, required this.access, required this.refresh});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    access: json['access'] as String,
    refresh: json['refresh'] as String,
  );
}
