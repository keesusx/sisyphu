class Evaluations {
  final int? id;
  final int? set;
  final String type;
  final int resultNumTime;
  final String elapsedTime;
  final String createdAt;
  final String updatedAt;

  Evaluations(
      {this.id,
      this.set,
      required this.type,
      required this.resultNumTime,
      required this.elapsedTime,
      required this.createdAt,
      required this.updatedAt});

  factory Evaluations.fromMap(Map<String, dynamic> json) => Evaluations(
        id: json['id'],
        set: json['set_id'],
        type: json['type'],
        resultNumTime: json['result_num_time'],
        elapsedTime: json['elapsed_time'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'set_id': set,
      'type': type,
      'result_num_time': resultNumTime,
      'elapsed_time': elapsedTime,
      'created_at': createdAt,
      'updated_at': updatedAt
    };
  }
}
