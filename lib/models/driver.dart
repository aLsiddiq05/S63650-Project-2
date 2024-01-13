class Driver {
  String id;
  String name;
  String email;
  String password;

  Driver({required this.id, required this.name, required this.email, required this.password});

  // Convert a Driver into a Map for Firebase
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
      };

    factory Driver.fromMap(Map<dynamic, dynamic> map, String id) {
    return Driver(
      id: id,
      name: map['name'],
      email: map['email'],
      password: map['password'],
    );
  }
}
