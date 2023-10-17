import 'package:flutter/material.dart';
import 'package:sisyphu/db/bodyparts_workouts.dart';
import '../db/evaluations.dart';
import '../db/sets.dart';
import '../db/db_helper.dart';

class ShowWorkoutScreen extends StatelessWidget {
  const ShowWorkoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Workouts'), WorkoutList(), Text('Sets'), SetList(), Text('Evaluations'), EvaluationList()],
          ),
        ));
  }

  Widget WorkoutList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper.instance.getWorkouts(),
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData) {
            return Container(
              child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: Text(snapshot.data![index]['workout'].toString()),
                      title: Text(snapshot.data![index]['name']),
                    );
                  }),
            );
          } else {
            return Center(child: Text('데이터가 없습니다.'));
          }
        });
  }

  Widget SetList() {
    return FutureBuilder<List<Sets>>(
        future: DBHelper.instance.getSets(),
        builder: (BuildContext context, AsyncSnapshot<List<Sets>> snapshot) {
          if (snapshot.hasData) {
            return Container(
              child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: Text(snapshot.data![index].id.toString()),
                      title: Text(snapshot.data![index].workout.toString() +
                          ' ' +
                          snapshot.data![index].weight.toString() +
                          'kg' +
                          ' ' +
                          snapshot.data![index].targetNumTime.toString() +
                          '회' +
                          snapshot.data![index].createdAt.toString()),
                    );
                  }),
            );
          } else {
            return Center(child: Text('데이터가 없습니다.'));
          }
        });
  }

  Widget EvaluationList() {
    return FutureBuilder<List<Evaluations>>(
        future: DBHelper.instance.getEvaluations(),
        builder: (BuildContext context, AsyncSnapshot<List<Evaluations>> snapshot) {
          if (snapshot.hasData) {
            return Container(
              child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: Text(snapshot.data![index].id.toString()),
                      title: Text('setID ' + snapshot.data![index].set.toString() + ' ' + snapshot.data![index].type.toString()),
                    );
                  }),
            );
          } else {
            return Center(child: Text('데이터가 없습니다.'));
          }
        });
  }
}
