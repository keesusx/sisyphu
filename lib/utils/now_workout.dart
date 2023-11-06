class NowWorkout {
  int id;
  String name;

  NowWorkout({ required this.id, required this.name });

  int get getWorkoutID => id;
  String get getWorkoutName => name;

  set setWorkoutID(int id) => id = id;
  set setWorkoutName(String name) => name = name;
  
}


