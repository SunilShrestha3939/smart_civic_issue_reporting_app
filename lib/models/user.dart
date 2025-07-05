// lib/models/user.dart

class User {
  final int id;
  final String username;
  final String email;
  final bool isStaff; // Corresponds to Django's is_staff or a custom admin flag

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.isStaff,
  });

  // Factory constructor to create a User from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      isStaff: json['is_staff'] as bool? ?? false, // Default to false if not provided
    );
  }

  // Method to convert User to JSON map (less common for client-side)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': username,
      'email': email,
      'is_staff': isStaff,
    };
  }
}