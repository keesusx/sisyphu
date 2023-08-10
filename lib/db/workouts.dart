class Workouts {
  final int? id;
  final String name;
  final String created_at;
  final String updated_at;

  Workouts(
      {this.id,
      required this.name,
      required this.created_at,
      required this.updated_at});

  factory Workouts.fromMap(Map<String, dynamic> json) => new Workouts(
        id: json['id'],
        name: json['name'],
        created_at: json['created_at'],
        updated_at: json['updated_at'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': created_at,
      'updated_at': updated_at
    };
  }
}
