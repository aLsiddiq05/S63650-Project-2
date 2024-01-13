class Manager {
  String id;
  String email;
  String password;

  Manager({
    required this.id,
    required this.email,
    required this.password,
  });

  factory Manager.fromMap(Map<dynamic, dynamic> map, String id) {
    return Manager(
      id: id,
      email: map['email'],
      password: map['password'],
    );
  }
}
