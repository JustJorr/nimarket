class User {
  final String id;
  final String email;
  final String username;
  final String role;
  final String? assignedShopId;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.assignedShopId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
      'assignedShopId': assignedShopId,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      username: map['username'],
      role: map['role'],
      assignedShopId: map['assignedShopId'],
    );
  }
}
