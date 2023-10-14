import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sisyphu/db/bodyparts.dart';
import 'package:sisyphu/db/bodyparts.dart';
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
        version: 29,
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
      await db.execute('DROP TABLE IF EXISTS bodyparts');
      await _onCreate(db, newVersion);
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE workouts(
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      body_part TEXT NOT NULL,
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
      set_order INTEGER,
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
      note TEXT,
      elapsed_time TEXT,
      created_at TEXT,
      updated_at TEXT
    )
    ''');

    await db.execute('''
      CREATE TABLE bodyparts(
      id INTEGER PRIMARY KEY,
      name TEXT,
      created_at TEXT,
      updated_at TEXT
      )
      ''');

    await db.insert('bodyparts', BodyParts(id: 1, name: '가슴', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    await db.insert('bodyparts', BodyParts(id: 2, name: '어깨', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    await db.insert('bodyparts', BodyParts(id: 3, name: '팔', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    await db.insert('bodyparts', BodyParts(id: 4, name: '복근', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    await db.insert('bodyparts', BodyParts(id: 5, name: '등', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    await db.insert('bodyparts', BodyParts(id: 6, name: '하체', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    
    
    // await db.insert('sets', Sets(id: 1, setOrder: 1, workout: 1, targetNumTime: 1, weight: 10, createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    // await db.insert('sets', Sets(id: 2, setOrder: 2, workout: 1, targetNumTime: 2, weight: 20, createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    // await db.insert('sets', Sets(id: 3, setOrder: 3, workout: 1, targetNumTime: 3, weight: 30, createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    
    // await db.insert('evaluations', Evaluations(id: 1, set: 1, elapsedTime: '00', resultNumTime: 1, type: 'SUCCESS', note: 'test', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    // await db.insert('evaluations', Evaluations(id: 2, set: 2, elapsedTime: '00', resultNumTime: 2, type: 'SUCCESS', note: 'test', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    // await db.insert('evaluations', Evaluations(id: 3, set: 3, elapsedTime: '00', resultNumTime: 3, type: 'SUCCESS', note: 'test', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    
    
    // await db.insert('sets', Sets(id: 4, setOrder: 1, workout: 1, targetNumTime: 1, weight: 10, createdAt: '2023-09-02', updatedAt: '2023-09-02').toMap());
    // await db.insert('sets', Sets(id: 5, setOrder: 2, workout: 1, targetNumTime: 2, weight: 20, createdAt: '2023-09-02', updatedAt: '2023-09-02').toMap());
    // await db.insert('sets', Sets(id: 6, setOrder: 3, workout: 1, targetNumTime: 3, weight: 30, createdAt: '2023-09-02', updatedAt: '2023-09-02').toMap());
    
    // await db.insert('evaluations', Evaluations(id: 4, set: 4, elapsedTime: '00', resultNumTime: 1, type: 'SUCCESS', note: '너무 무겁다..(1)', createdAt: '2023-09-02', updatedAt: '2023-09-02').toMap());
    // await db.insert('evaluations', Evaluations(id: 5, set: 5, elapsedTime: '00', resultNumTime: 2, type: 'SUCCESS', note: '조금 쉬운데?(2)', createdAt: '2023-09-02', updatedAt: '2023-09-02').toMap());
    // await db.insert('evaluations', Evaluations(id: 6, set: 6, elapsedTime: '00', resultNumTime: 3, type: 'SUCCESS', note: 'test(3)', createdAt: '2023-09-02', updatedAt: '2023-09-02').toMap());
    
    
    // await db.insert('sets', Sets(id: 7, setOrder: 1, workout: 2, targetNumTime: 1, weight: 10, createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    // await db.insert('sets', Sets(id: 8, setOrder: 2, workout: 2, targetNumTime: 2, weight: 20, createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    // await db.insert('sets', Sets(id: 9, setOrder: 3, workout: 2, targetNumTime: 3, weight: 30, createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    
    // await db.insert('evaluations', Evaluations(id: 7, set: 7, elapsedTime: '00', resultNumTime: 1, type: 'SUCCESS', note: 'test', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    // await db.insert('evaluations', Evaluations(id: 8, set: 8, elapsedTime: '00', resultNumTime: 2, type: 'SUCCESS', note: 'test', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());
    // await db.insert('evaluations', Evaluations(id: 9, set: 9, elapsedTime: '00', resultNumTime: 3, type: 'SUCCESS', note: 'test', createdAt: '2023-09-01', updatedAt: '2023-09-01').toMap());

  }

  Future<int> insertWorkouts(Workouts workout) async {
    Database db = await instance.database;
    try {
      var result = await db.insert('workouts', workout.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      return result;
  } catch (e) {
      throw Exception(e);
  } 
  }

  Future<int> insertSets(Sets set) async {
    Database db = await instance.database;
    return await db.insert('sets', set.toMap());
  }

  Future<int> insertEvaluations(Evaluations evaluation) async {
    Database db = await instance.database;
    return await db.insert('evaluations', evaluation.toMap());
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
    // print(sets);
    List<Sets> setList = sets.isNotEmpty ? sets.map((c) => Sets.fromMap(c)).toList() : [];
    return setList;
  }

  Future<List<Map<String, dynamic>>> getWorkoutWithBodyPart() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT workouts.name AS workout_name, bodyparts.name AS bodypart_name FROM workouts, bodyparts WHERE workouts.body_part = bodyparts.id ORDER BY workouts.created_at');
    return result;
  }

  Future<List<Evaluations>> getEvaluations() async {
    Database db = await instance.database;
    var evaluations = await db.query('evaluations', orderBy: 'created_at');
    List<Evaluations> evaluationList = evaluations.isNotEmpty ? evaluations.map((c) => Evaluations.fromMap(c)).toList() : [];
    return evaluationList;
  }

  Future<List<BodyParts>> getBodyParts() async {
    Database db = await instance.database;
    var bodyparts = await db.query('bodyparts', orderBy: 'id');
    List<BodyParts> bodypartList = bodyparts.isNotEmpty ? bodyparts.map((c) => BodyParts.fromMap(c)).toList() : [];
    return bodypartList;
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
        'SELECT bodyparts.name AS bodypart_name, (julianday(?) -  julianday(sets.created_at)) AS datediff, COUNT(sets.id) AS count, MIN(sets.weight) AS minimum_weight, MAX(sets.weight) AS maximum_weight, ROUND(AVG(sets.weight), 1) AS average_weight, MIN(sets.target_num_time) AS minimum_reps, MAX(sets.target_num_time) AS maximum_reps, ROUND(AVG(sets.target_num_time), 1) AS average_reps, SUM(sets.target_num_time * sets.weight) AS volumn, workouts.name, sets.weight, sets.target_num_time, sets.created_at FROM bodyparts, sets, workouts WHERE bodyparts.id = workouts.body_part AND sets.workout = workouts.id GROUP BY SUBSTR(sets.created_at, 0, 10), workouts.id ORDER BY sets.created_at',
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
        'SELECT DISTINCT evaluations.id as evaluationsID, sets.id, sets.workout, sets.weight, sets.target_num_time, workouts.name, sets.created_at, evaluations.type, evaluations.note, evaluations.elapsed_time FROM sets, workouts, evaluations WHERE SUBSTR(sets.created_at, 0, 10) = ? AND sets.workout = workouts.id AND evaluations.set_id = sets.id ORDER BY sets.created_at',
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

  Future<List<Map<String, dynamic>>> getWeightsRepsToday(int workout) async {
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
        'SELECT sets.workout, workouts.name, SUBSTR(sets.created_at, 0, 10) as workout_date FROM sets, workouts WHERE sets.workout = workouts.body_part AND SUBSTR(sets.created_at, 0, 10) > ? AND SUBSTR(sets.created_at, 0, 10) < ? GROUP BY sets.workout ORDER BY sets.created_at ASC',
        [secondLatestWorkoutDate.first['created_at'].toString().substring(0, 10), today]);

    return targetWorkoutIds;
  }

  Future<List<Map<String, dynamic>>> getWholeSetsInfo(List<Map<String, dynamic>> workoutIdList) async {
    List<Map<String, dynamic>> result = [];
    Database db = await instance.database;

    for (int i = 0; i < workoutIdList.length; i++) {
      var temp = await db.rawQuery(
          'SELECT workouts.id AS workout_id, workouts.name AS workout_name, sets.set_order, evaluations.result_num_time AS reps, sets.weight, sets.created_at AS workout_date FROM sets, evaluations, workouts WHERE workouts.id = sets.workout AND evaluations.set_id = sets.id AND sets.workout = ? ORDER BY sets.id ASC',
          [workoutIdList[i]['workout']]);
      result.addAll(temp);
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getLatestSetHistory(int workoutID) async {
    Database db = await instance.database;
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String today = formatter.format(DateTime.now());

    var result;

    var recentDates = await db.rawQuery('SELECT SUBSTR(created_at, 0 ,10) AS done_date FROM sets WHERE workout = ? AND NOT SUBSTR(created_at, 0 ,10) IN (?) GROUP BY SUBSTR(created_at, 0 ,10) ORDER BY id DESC', [workoutID, today]);
    if(recentDates.length > 0) {
       result = await db.rawQuery(
          'SELECT sets.set_order, sets.weight, evaluations.result_num_time, evaluations.type, evaluations.note, SUBSTR(sets.created_at, 0 ,10) AS created_at FROM sets INNER JOIN evaluations ON evaluations.set_id = sets.id WHERE sets.workout = ? AND SUBSTR(sets.created_at, 0, 10) = ? ORDER BY sets.created_at ASC',
          [workoutID, recentDates[0]['done_date']]);
       return result;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getBodyPartName(int workoutID) async {
    Database db = await instance.database;

    var result = await db.rawQuery('SELECT bodyparts.name FROM bodyparts INNER JOIN workouts ON workouts.body_part = bodyparts.id WHERE workouts.id = ?', [workoutID]);
    // print(result);
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

  Future<List<Map<String, dynamic>>> getworkoutDates(int workoutID) async {
    Database db = await instance.database;

    var result = await db.rawQuery('SELECT SUBSTR(created_at, 0, 10) FROM sets WHERE workout = ? GROUP BY SUBSTR(created_at, 0, 10) ORDER BY id DESC LIMIT 3', [workoutID]);
    // print(result);
    return result;
  }

  Future<List<Map<String, dynamic>>> getNote(int workoutID, int setOrder) async {
    Database db = await instance.database;

    var result = await db.rawQuery('SELECT evaluations.note FROM sets INNER JOIN evaluations ON evaluations.set_id = sets.id WHERE sets.workout = ? AND sets.set_order = ? ORDER BY sets.created_at DESC LIMIT 2', [workoutID, setOrder]);
    // print(result);
    return result;
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

  static void updateNote(int setID, String note) async {
    Map<String, dynamic> data = {'note': note};
    Database db = await instance.database;
    await db.update('evaluations', data, where: 'id = ?', whereArgs: [setID]);
  }

  static void updateEvaluationType(int setID, String type) async {
    Map<String, dynamic> data = {'type': type};
    Database db = await instance.database;
    await db.update('evaluations', data, where: 'id = ?', whereArgs: [setID]);
  }

  static void deleteSet(int id) async {
    Database db = await instance.database;
    await db.rawDelete('DELETE FROM sets WHERE id = ? ', [id]);
  }
}
