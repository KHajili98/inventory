// ── User Role ─────────────────────────────────────────────────────────────────

enum UserRole {
  admin,
  manager,
  staff,
  viewer,
  warehouseStaff,
  supervisor,
  accountant,
  salesRep,
  unknown;

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'staff':
        return UserRole.staff;
      case 'viewer':
        return UserRole.viewer;
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
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.staff:
        return 'Staff';
      case UserRole.viewer:
        return 'Viewer';
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
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.staff:
        return 'staff';
      case UserRole.viewer:
        return 'viewer';
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

class LoginInventory {
  final String id;
  final String name;
  final String address;
  final bool isStock;

  const LoginInventory({required this.id, required this.name, required this.address, required this.isStock});

  factory LoginInventory.fromJson(Map<String, dynamic> json) => LoginInventory(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String? ?? '',
    isStock: json['is_stock'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'address': address, 'is_stock': isStock};
}

class LoginResponse {
  final AuthUser user;
  final String access;
  final String refresh;
  final LoginInventory? loggedInInventory;

  const LoginResponse({required this.user, required this.access, required this.refresh, this.loggedInInventory});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    // Server nests logged_in_inventory_details inside the user object.
    // Fall back to root-level logged_in_inventory for backwards compatibility.
    final inventoryJson =
        (userJson['logged_in_inventory_details'] as Map<String, dynamic>?) ?? (json['logged_in_inventory'] as Map<String, dynamic>?);
    return LoginResponse(
      user: AuthUser.fromJson(userJson),
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      loggedInInventory: inventoryJson != null ? LoginInventory.fromJson(inventoryJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {'user': user.toJson(), 'access': access, 'refresh': refresh, 'logged_in_inventory': loggedInInventory?.toJson()};
}
