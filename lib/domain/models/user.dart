/// User role enum
enum UserRole {
  specialist,
  client,
}

/// Base user model
class User {
  final int? id;
  final String email;
  final String passwordHash; // In production, this should be hashed
  final UserRole role;
  final String name;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool isTwoFactorEnabled;
  final String? profileImagePath;

  User({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.name,
    this.phone,
    this.createdAt,
    this.lastLoginAt,
    this.isTwoFactorEnabled = false,
    this.profileImagePath,
  });

  /// Create from database map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'] as String,
        orElse: () => UserRole.client,
      ),
      name: map['name'] as String,
      phone: map['phone'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
      isTwoFactorEnabled: (map['is_two_factor_enabled'] as int? ?? 0) == 1,
      profileImagePath: map['profile_image_path'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'password_hash': passwordHash,
      'role': role.name,
      'name': name,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_two_factor_enabled': isTwoFactorEnabled ? 1 : 0,
      'profile_image_path': profileImagePath,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? passwordHash,
    UserRole? role,
    String? name,
    String? phone,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isTwoFactorEnabled,
    String? profileImagePath,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

