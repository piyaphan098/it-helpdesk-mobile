/// User role enum matching Supabase `user_role` type.
enum UserRole {
  employee('employee'),
  technician('technician'),
  admin('admin');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.employee,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.employee:
        return 'Employee';
      case UserRole.technician:
        return 'Technician';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isTechnician => this == UserRole.technician;
  bool get isEmployee => this == UserRole.employee;
  bool get canManageTickets => isTechnician || isAdmin;
}
