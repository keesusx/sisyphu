class Target {
  int workoutID;
  String workoutName;
  int bodypartID;
  int? order;

  Target({required this.workoutID, required this.workoutName, required this.bodypartID, this.order});

  // getter
  int get getWorkoutID => workoutID;
  String get getWorkoutName => workoutName;
  int get getBodyPartID => bodypartID;
  int? get getOrder => order;
  
    factory Target.fromMap(Map<String, dynamic> json) => Target(
        workoutID: json['workout'],
        workoutName: json['name'],
        bodypartID: int.parse(json['body_part']),
      );

}