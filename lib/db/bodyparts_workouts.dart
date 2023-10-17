class BodypartsWorkouts {
  final int? id;
  final int? workout;
  final String? bodypart;
  final String createdAt;
  final String updatedAt;

  BodypartsWorkouts({this.id, this.workout, this.bodypart, required this.createdAt, required this.updatedAt});

  factory BodypartsWorkouts.fromMap(Map<String, dynamic> json) => BodypartsWorkouts(
        id: json['id'],
        workout: json['workout'],
        bodypart: json['bodypart'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toMap() {
    return {'id': id, 'workout': workout, 'bodypart': bodypart, 'created_at': createdAt, 'updated_at': updatedAt};
  }
}
