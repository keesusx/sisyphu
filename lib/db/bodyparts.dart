class BodyParts {
  final int? id;
  final String? name;
  final String createdAt;
  final String updatedAt;

  BodyParts({this.id, this.name, required this.createdAt, required this.updatedAt});

  factory BodyParts.fromMap(Map<String, dynamic> json) => BodyParts(
        id: json['id'],
        name: json['name'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'created_at': createdAt, 'updated_at': updatedAt};
  }
}
