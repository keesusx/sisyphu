class Sets {
  final int? id;
  final int? workout;
  final int targetNumTime;
  final int? weight;
  final String createdAt;
  final String updatedAt;

  Sets(
      {this.id,
      required this.workout,
      required this.targetNumTime,
      required this.weight,
      required this.createdAt,
      required this.updatedAt});

  factory Sets.fromMap(Map<String, dynamic> json) => Sets(
        id: json['id'],
        workout: json['workout'],
        targetNumTime: json['target_num_time'],
        weight: json['weight'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout': workout,
      'target_num_time': targetNumTime,
      'weight': weight,
      'created_at': createdAt,
      'updated_at': updatedAt
    };
  }
}
