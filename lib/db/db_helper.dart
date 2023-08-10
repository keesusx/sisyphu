import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sisyphu/db/bodyparts_workouts.dart';
import 'package:sisyphu/db/workouts.dart';
import 'package:sqflite/sqflite.dart';
import 'evaluations.dart';
import 'sets.dart';

class DBHelper {
  DBHelper._privateConstructor();

  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'database.db');
    return await openDatabase(path,
        version: 2,
        onCreate: _onCreate,
        // onConfigure: _onConfigure
        onUpgrade: _onUpgrade);
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS workouts');
      await db.execute('DROP TABLE IF EXISTS sets');
      await db.execute('DROP TABLE IF EXISTS evaluations');
      await db.execute('DROP TABLE IF EXISTS bodyparts_workouts');
      await _onCreate(db, newVersion);
    }
  }

  Future _onConfigure(Database db) async {
    await db.execute('DROP TABLE IF EXISTS workouts');
    await db.execute('DROP TABLE IF EXISTS sets');
    await db.execute('DROP TABLE IF EXISTS evaluations');
    await db.execute('DROP TABLE IF EXISTS bodyparts_workouts');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE workouts(
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      created_at TEXT,
      updated_at TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE sets(
      id INTEGER PRIMARY KEY,
      workout INTEGER,
      target_num_time INTEGER,
      weight INTEGER,
      created_at TEXT,
      updated_at TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE evaluations(
      id INTEGER PRIMARY KEY,
      set_id INTEGER,
      type TEXT,
      result_num_time INTEGER,
      elapsed_time TEXT,
      created_at TEXT,
      updated_at TEXT
    )
    ''');

    await db.execute('''
      CREATE TABLE bodyparts_workouts(
      id INTEGER PRIMARY KEY,
      workout INTEGER,
      bodypart TEXT,
      created_at TEXT,
      updated_at TEXT
      )
      ''');
  }

  Future<int> insertWorkouts(Workouts workout) async {
    Database db = await instance.database;
    return await db.insert('workouts', workout.toMap());
  }

  Future<int> insertSets(Sets set) async {
    Database db = await instance.database;
    return await db.insert('sets', set.toMap());
  }

  Future<int> insertEvaluations(Evaluations evaluation) async {
    Database db = await instance.database;
    return await db.insert('evaluations', evaluation.toMap());
  }

  Future<int> insertBodypartsWorkouts(BodypartsWorkouts bodypartsWorkouts) async {
    Database db = await instance.database;
    return await db.insert('bodyparts_workouts', bodypartsWorkouts.toMap());
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> workouts =
        await db.rawQuery('SELECT id AS workout, name, SUBSTR(created_at, 0, 10) AS workout_date FROM workouts ORDER BY created_at');
    return workouts;
  }

  Future<List<Sets>> getSets() async {
    Database db = await instance.database;
    var sets = await db.rawQuery('SELECT * FROM sets ORDER BY created_at DESC');
    print(sets);
    List<Sets> setList = sets.isNotEmpty ? sets.map((c) => Sets.fromMap(c)).toList() : [];
    return setList;
  }

  Future<List<Map<String, dynamic>>> getWorkoutWithBodyPart() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM workouts, bodyparts_workouts WHERE workouts.id = bodyparts_workouts.workout ORDER BY workouts.created_at');
    return result;
  }

  Future<List<Evaluations>> getEvaluations() async {
    Database db = await instance.database;
    var evaluations = await db.query('evaluations', orderBy: 'created_at');
    List<Evaluations> evaluationList = evaluations.isNotEmpty ? evaluations.map((c) => Evaluations.fromMap(c)).toList() : [];
    return evaluationList;
  }

  Future<List<BodypartsWorkouts>> getBodypartsWorkouts() async {
    Database db = await instance.database;
    var bodypartsWorkouts = await db.query('bodyparts_workouts', orderBy: 'created_at');
    List<BodypartsWorkouts> bodypartsWorkoutsList = bodypartsWorkouts.isNotEmpty ? bodypartsWorkouts.map((c) => BodypartsWorkouts.fromMap(c)).toList() : [];
    // print(bodypartsWorkouts);
    return bodypartsWorkoutsList;
  }

  Future<List<Map<String, dynamic>>> getWorkoutedDates() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT sets.created_at FROM sets GROUP BY sets.created_at ORDER BY sets.created_at');
    return result;
  }

  Future<List<Map<String, dynamic>>> getSetsInGroup() async {
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String today = formatter.format(DateTime.now());
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT (julianday(?) -  julianday(sets.created_at)) AS datediff, bodyparts_workouts.bodypart, COUNT(sets.id) AS count, MIN(sets.weight) AS minimum_weight, MAX(sets.weight) AS maximum_weight, ROUND(AVG(sets.weight), 1) AS average_weight, MIN(sets.target_num_time) AS minimum_reps, MAX(sets.target_num_time) AS maximum_reps, ROUND(AVG(sets.target_num_time), 1) AS average_reps, SUM(sets.target_num_time * sets.weight) AS volumn, workouts.name, sets.weight, sets.target_num_time, sets.created_at FROM sets, workouts, bodyparts_workouts WHERE bodyparts_workouts.workout = workouts.id AND sets.workout = workouts.id GROUP BY SUBSTR(sets.created_at, 0, 10) , workouts.id ORDER BY sets.created_at',
        [today]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getElapsedWorkoutTime(DateTime date) async {
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String today = formatter.format(date);
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT SUM(evaluations.elapsed_time) AS sum FROM evaluations WHERE evaluations.created_at >= ? ORDER BY evaluations.created_at DESC', [today]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getCompletedWorkouts() async {
    List<Map<String, dynamic>> result = [];
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String today = formatter.format(DateTime.now());

    Database db = await instance.database;
    result = await db.rawQuery(
        'SELECT DISTINCT sets.id, sets.workout, sets.weight, sets.target_num_time, workouts.name, sets.created_at, evaluations.type, evaluations.elapsed_time FROM sets, workouts, evaluations WHERE SUBSTR(sets.created_at, 0, 10) = ? AND sets.workout = workouts.id AND evaluations.set_id = sets.id ORDER BY sets.created_at',
        [today]);
    return result;
  }

  Future<int> getCompletedSetsToday(int workout) async {
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String today = formatter.format(DateTime.now());
    Database db = await instance.database;
    List<Map<String, dynamic>> queryResult =
        await db.rawQuery('SELECT COUNT(*) AS sets FROM sets WHERE sets.workout = ? AND SUBSTR(sets.created_at, 0, 10) = ?', [workout, today]);
    int result = queryResult.first['sets'];
    return result;
  }

  Future<List<Map<String, dynamic>>> getLatestWeightsRepsToday(int workout) async {
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String today = formatter.format(DateTime.now());
    Database db = await instance.database;
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT weight, target_num_time AS reps FROM sets WHERE SUBSTR(sets.created_at, 0 ,10) = ? AND sets.workout = ?', [today, workout]);
    return result;
  }

  Future<List<Map<String, Object?>>> getTodayTargetWorkoutId() async {
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String today = formatter.format(DateTime.now());
    Database db = await instance.database;
    List<Map<String, dynamic>> latestWorkoutDate = await db.rawQuery(
        'SELECT SUBSTR(created_at, 0, 10) as created_at FROM sets WHERE SUBSTR(created_at, 0, 10) < ? GROUP BY SUBSTR(created_at, 0, 10) ORDER BY id DESC',
        [today]);
    if (latestWorkoutDate.length == 0) {
      return [];
    }
    List<Map<String, dynamic>> latestWorkoutId =
        await db.rawQuery('SELECT sets.workout FROM sets WHERE SUBSTR(created_at, 0, 10) = ? GROUP BY sets.workout', [latestWorkoutDate.first['created_at']]);
    List<Map<String, dynamic>> secondLatestWorkoutDate = await db.rawQuery(
        'SELECT SUBSTR(created_at, 0, 10) as created_at FROM sets WHERE SUBSTR(created_at, 0, 10) < ? AND workout = ? ORDER BY id DESC',
        [latestWorkoutDate.first['created_at'], latestWorkoutId.first['workout']]);
    if (secondLatestWorkoutDate.length == 0) {
      return [];
    }
    List<Map<String, dynamic>> targetWorkoutIds = await db.rawQuery(
        'SELECT sets.workout, workouts.name, SUBSTR(sets.created_at, 0, 10) as workout_date FROM sets, workouts WHERE sets.workout = workouts.id AND SUBSTR(sets.created_at, 0, 10) > ? AND SUBSTR(sets.created_at, 0, 10) < ? GROUP BY sets.workout ORDER BY sets.created_at ASC',
        [secondLatestWorkoutDate.first['created_at'].toString().substring(0, 10), today]);
    return targetWorkoutIds;
  }

  Future<List<Map<String, dynamic>>> getWholeSetsInfo(List<Map<String, dynamic>> workoutIdList) async {
    List<Map<String, dynamic>> result = [];
    Database db = await instance.database;

    for (int i = 0; i < workoutIdList.length; i++) {
      var temp = await db.rawQuery(
          'SELECT workouts.id AS workout_id, workouts.name AS workout_name, evaluations.result_num_time AS reps, sets.weight, sets.created_at AS workout_date FROM sets, evaluations, workouts WHERE workouts.id = sets.workout AND evaluations.set_id = sets.id AND sets.workout = ? AND SUBSTR(sets.created_at, 0, 10) = ? ORDER BY sets.id ASC',
          [workoutIdList[i]['workout'], workoutIdList[i]['workout_date']]);
      result.addAll(temp);
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getDateByWorkout(int workoutID) async {
    Database db = await instance.database;

    const int limit = 10;
    List<Map<String, dynamic>> volumes = [];
    List<Map<String, dynamic>> dates = await db.rawQuery(
        'SELECT SUBSTR(sets.created_at, 0, 10) as date FROM sets WHERE sets.workout = ? GROUP BY SUBSTR(sets.created_at, 0 , 10) ORDER BY sets.id DESC LIMIT ?',
        [workoutID, limit]);

    for (var date in dates) {
      var temp = await db.rawQuery(
          'SELECT SUM(weight * target_num_time) as volumn, SUBSTR(sets.created_at, 0 , 10) as date FROM sets WHERE sets.workout = ? AND SUBSTR(sets.created_at, 0 , 10) = ?',
          [workoutID, date['date']]);
      volumes.add(temp.first);
    }
    return volumes;
  }

  static void updateWeight(int setID, int weight) async {
    Map<String, dynamic> data = {'id': setID, 'weight': weight};
    Database db = await instance.database;
    await db.update('sets', data, where: 'id = ?', whereArgs: [setID]);
  }

  static void updateReps(int setID, int reps) async {
    Map<String, dynamic> data = {'id': setID, 'target_num_time': reps};
    Database db = await instance.database;
    await db.update('sets', data, where: 'id = ?', whereArgs: [setID]);
  }

  static void deleteSet(int id) async {
    Database db = await instance.database;
    await db.rawDelete('DELETE FROM sets WHERE id = ? ', [id]);
  }
}
