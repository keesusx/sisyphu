class DailyBodyStats {
  final int? id;
  final double? weight;
  final double? skeletalMuscle;
  final int? fatRate;
  final String? note;
  final String createdAt;
  final String updatedAt;

  DailyBodyStats({ this.id, this.weight, this.skeletalMuscle, this.fatRate, this.note, required this.createdAt, required this.updatedAt});

  factory DailyBodyStats.fromMap(Map<String, dynamic> json) => DailyBodyStats(
        id: json['id'],
        weight: json['weight'],
        skeletalMuscle: json['skeletal_muscle'],
        fatRate: json['fat_rate'],
        note: json['note'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'skeletal_muscle': skeletalMuscle,
      'fat_rate': fatRate,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt
    };
  }
}