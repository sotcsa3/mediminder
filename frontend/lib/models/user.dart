// MediMinder – User Model

class AppUser {
  final String id;
  final String email;
  final String name;

  AppUser({
    required this.id,
    required this.email,
    this.name = 'Kedves Felhasználó',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? json['displayName'] as String? ?? 'Kedves Felhasználó',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
      };
}
