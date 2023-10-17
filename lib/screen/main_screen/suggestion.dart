class Suggestion {
  int setNumber;
  int? lastWeight;
  int? lastReps;
  String? lastEvaluationType;
  String? lastNote;
  int? nextWeight;
  int? nextReps;
  String? nextEvaluationType;
  int? volumn;
  String? nextWorkout;

  Suggestion(
      {required this.setNumber,
      this.lastWeight,
      this.lastReps,
      this.lastEvaluationType,
      this.lastNote,
      this.nextWeight,
      this.nextReps,
      this.nextEvaluationType,
      this.volumn,
      this.nextWorkout});
}
